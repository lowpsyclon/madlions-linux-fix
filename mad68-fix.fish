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
    echo "[WARN] $argv"
end

function fail
    echo "[ERROR] $argv" >&2
    exit 1
end

function need_cmd
    if not command -q $argv[1]
        fail "Missing command: $argv[1]"
    end
end

if test (id -u) -eq 0
    fail "Do not run as root. Use a regular user with sudo."
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

info "Searching for Madlions MAD68 keyboard ($VENDOR_ID:$PRODUCT_ID)..."
set -l KB_LINE (lsusb | grep -i "$VENDOR_ID:$PRODUCT_ID")

if test -z "$KB_LINE"
    fail "MAD68 keyboard not found. Please connect it and run the script again."
end

ok "Keyboard detected:"
echo "    $KB_LINE"

if not getent group $GROUP_NAME >/dev/null
    info "Creating group '$GROUP_NAME'..."
    sudo groupadd $GROUP_NAME
    or fail "Failed to create group '$GROUP_NAME'."
    ok "Group '$GROUP_NAME' created."
else
    ok "Group '$GROUP_NAME' already exists."
end

set -l USER_IN_GROUP 0
if id -nG $CURRENT_USER | string match -rq "(^| )$GROUP_NAME( |$)"
    set USER_IN_GROUP 1
    ok "User '$CURRENT_USER' is already in group '$GROUP_NAME'."
else
    info "Adding '$CURRENT_USER' to group '$GROUP_NAME'..."
    sudo usermod -aG $GROUP_NAME $CURRENT_USER
    or fail "Failed to add '$CURRENT_USER' to group '$GROUP_NAME'."
    ok "User added to group '$GROUP_NAME'."
end

set -l RULE_TEXT "KERNEL==\"hidraw*\", SUBSYSTEM==\"hidraw\", ATTRS{idVendor}==\"$VENDOR_ID\", ATTRS{idProduct}==\"$PRODUCT_ID\", GROUP=\"$GROUP_NAME\", MODE=\"0660\""

info "Writing udev rule to $RULE_FILE ..."
printf "%s\n" $RULE_TEXT | sudo tee $RULE_FILE >/dev/null
or fail "Failed to write udev rule."

ok "Rule saved."

info "Reloading udev rules..."
sudo udevadm control --reload-rules
or fail "Failed to reload udev rules."

sudo udevadm trigger
or fail "Failed to apply udev trigger."

ok "udev reloaded."

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
    fail "No matching hidraw interfaces found."
end

ok "MAD68 hidraw interfaces:"
for d in $HID_MATCHES
    echo "    $d"
end

info "Applying immediate permissions for current session..."
for d in $HID_MATCHES
    sudo chgrp $GROUP_NAME $d
    or fail "Failed to change group on $d"

    sudo chmod 0660 $d
    or fail "Failed to change permissions on $d"

    if command -q setfacl
        sudo setfacl -m u:$CURRENT_USER:rw $d
    end
end

ok "Permissions applied."

echo
info "Final device state:"
for d in $HID_MATCHES
    ls -l $d
end

echo
ok "Done."
echo "The keyboard should now be detected by the web configurator."

echo "For permanent access, logout/login is recommended."

if test $USER_IN_GROUP -eq 0
    warn "User was added to a new group. Logout/login is required for full effect."
end

echo
echo "Open the configurator using Chromium or Google Chrome."
