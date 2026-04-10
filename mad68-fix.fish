#!/usr/bin/env fish

set -l VENDOR_ID "373b"
set -l PRODUCT_ID "105c"
set -l GROUP_NAME "hidaccess"
set -l RULE_FILE "/etc/udev/rules.d/99-madlions.rules"

function info
    echo "[INFO] $argv"
end

function ok
    echo "[OK] $argv"
end

function warn
    echo "[AVISO] $argv"
end

function fail
    echo "[ERRO] $argv" >&2
    exit 1
end

function need_cmd
    if not command -q $argv[1]
        fail "Comando ausente: $argv[1]"
    end
end

if test (id -u) -eq 0
    fail "Não rode como root. Use seu usuário normal."
end

need_cmd lsusb
need_cmd udevadm
need_cmd sudo
need_cmd grep
need_cmd getent
need_cmd id
need_cmd chmod
need_cmd chgrp

set -l CURRENT_USER $USER
if test -z "$CURRENT_USER"
    set CURRENT_USER (id -un)
end

info "Procurando teclado Madlions MAD68 ($VENDOR_ID:$PRODUCT_ID)..."
set -l KB_LINE (lsusb | grep -i "$VENDOR_ID:$PRODUCT_ID")

if test -z "$KB_LINE"
    fail "Teclado MAD68 não encontrado. Conecte o teclado e rode o script de novo."
end

ok "Teclado detectado:"
echo "    $KB_LINE"

if not getent group $GROUP_NAME >/dev/null
    info "Criando grupo '$GROUP_NAME'..."
    sudo groupadd $GROUP_NAME
    or fail "Não consegui criar o grupo '$GROUP_NAME'."
    ok "Grupo '$GROUP_NAME' criado."
else
    ok "Grupo '$GROUP_NAME' já existe."
end

set -l USER_IN_GROUP 0
if id -nG $CURRENT_USER | string match -rq "(^| )$GROUP_NAME( |$)"
    set USER_IN_GROUP 1
    ok "Usuário '$CURRENT_USER' já está no grupo '$GROUP_NAME'."
else
    info "Adicionando '$CURRENT_USER' ao grupo '$GROUP_NAME'..."
    sudo usermod -aG $GROUP_NAME $CURRENT_USER
    or fail "Não consegui adicionar '$CURRENT_USER' ao grupo '$GROUP_NAME'."
    ok "Usuário adicionado ao grupo '$GROUP_NAME'."
end

set -l RULE_TEXT "KERNEL==\"hidraw*\", SUBSYSTEM==\"hidraw\", ATTRS{idVendor}==\"$VENDOR_ID\", ATTRS{idProduct}==\"$PRODUCT_ID\", GROUP=\"$GROUP_NAME\", MODE=\"0660\""

info "Gravando regra permanente em $RULE_FILE ..."
printf "%s\n" $RULE_TEXT | sudo tee $RULE_FILE >/dev/null
or fail "Não consegui gravar a regra udev."

ok "Regra salva."

info "Recarregando regras do udev..."
sudo udevadm control --reload-rules
or fail "Falha ao recarregar o udev."

sudo udevadm trigger
or fail "Falha ao aplicar trigger do udev."

ok "udev recarregado."

set -l HID_MATCHES

for d in /dev/hidraw*
    if test -e $d
        set -l UDEV_OUT (udevadm info -a -n $d 2>/dev/null)
        if string match -rq "ATTRS{idVendor}==\"$VENDOR_ID\"" -- $UDEV_OUT
            if string match -rq "ATTRS{idProduct}==\"$PRODUCT_ID\"" -- $UDEV_OUT
                set HID_MATCHES $HID_MATCHES $d
            end
        end
    end
end

if test (count $HID_MATCHES) -eq 0
    fail "Não encontrei interfaces hidraw do teclado."
end

ok "Interfaces hidraw do MAD68:"
for d in $HID_MATCHES
    echo "    $d"
end

info "Aplicando permissão imediata para funcionar já nesta sessão..."
for d in $HID_MATCHES
    sudo chgrp $GROUP_NAME $d
    or fail "Falha em chgrp $d"

    sudo chmod 0660 $d
    or fail "Falha em chmod $d"

    if command -q setfacl
        sudo setfacl -m u:$CURRENT_USER:rw $d
    end
end

ok "Permissões imediatas aplicadas."

echo
info "Estado final dos dispositivos:"
for d in $HID_MATCHES
    ls -l $d
end

echo
ok "Pronto."
echo "Agora o teclado já deve ser reconhecido pelo configurador web nesta sessão."
echo "Para o acesso continuar normal nas próximas sessões/conexões, faça logout/login quando puder."

if test $USER_IN_GROUP -eq 0
    warn "Você foi adicionado a um grupo novo. O script já liberou acesso agora via ACL, mas o logout/login é o que consolida isso permanentemente."
end

echo
echo "Abra o Chromium/Chrome e teste o configurador."
