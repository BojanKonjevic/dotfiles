# bootstrap-override.nix — AUTO-GENERATED, delete after post-boot agenix setup.
#
# Post-boot steps to restore full agenix:
#   On your existing machine:
#     1. Add the new host pubkey to secrets/secrets.nix:
#          ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMaf2UoMp+qIjL3TNq9f9bmpfun3D8VrKzbKdtb67T0s root@nixos
#     2. agenix -r -i ~/.ssh/id_ed25519
#     3. git add -A && git commit -m "add desktop host key" && git push
#   On this machine (after git pull):
#     4. rm /home/bojan/dotfiles/modules/hosts/desktop/bootstrap-override.nix
#     5. Set bootstrapMode = false in user.nix
#     6. nr
{...}: {
  users.users.bojan.initialHashedPassword = "$6$xEL3OQ10YEW/XJxt$eeNAM/FdiG.h50/2F3xsLY8lax/JrWaHHHTGEgalQ6xk.zQZboGBAetJyBNwZAZQBBQagnsIib9TrPADCjsrX.";
}
