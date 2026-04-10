# madlions-linux-fix

Script em Fish para corrigir o acesso do configurador web do teclado magnético Madlions MAD68 no Linux.

## O que ele faz

- detecta o MAD68 (`373b:105c`)
- cria o grupo `hidaccess`
- adiciona seu usuário ao grupo
- cria a regra `udev`
- recarrega o `udev`
- aplica permissão imediata na sessão atual
- evita usar `0666` permanente

## Uso

```fish
chmod +x mad68-fix.fish
./mad68-fix.fish
```

Depois, teste no Chromium/Chrome.

Se o script adicionou seu usuário ao grupo `hidaccess`, faça logout/login depois para consolidar a permissão permanente.
