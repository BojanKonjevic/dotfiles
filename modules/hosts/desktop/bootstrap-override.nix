# bootstrap-override.nix — AUTO-GENERATED, delete after post-boot agenix setup.
#
# Post-boot steps to restore full agenix:
#   On your existing machine:
#     1. Add the new host pubkey to secrets/secrets.nix:
#          ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILYjhXex3hHSQ4Dv/86f+iUbcYn/eFJybGd/ybhODi5Y root@nixos
#     2. agenix -r -i ~/.ssh/id_ed25519
#     3. git add -A && git commit -m "add desktop host key" && git push
#   On this machine (after git pull):
#     4. rm /home/bojan/dotfiles/modules/hosts/desktop/bootstrap-override.nix
#     5. Set bootstrapMode = false in user.nix
#     6. nr
{ ... }:
{
  users.users.bojan.initialHashedPassword = "$6$UTYO/WAuaZa82lPp$3V4Q7Otn8LmbUwGsOTgSA87DddC6yn8FGlTTUpeB6t3vq1zd31sIzjJsQrNz/74KA4Tq3MtE/yZhzDM3l8qaQ1";
}
