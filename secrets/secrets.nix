let
  desktop = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAING4ciuYkiTBBwhcgaHao+IoNxy0RxOJAw7aoF4gJ6yV root@desktop";
in {
  "user-password.age".publicKeys = [desktop];
  "cachix-token.age".publicKeys = [desktop];
}
