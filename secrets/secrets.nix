let
  desktop = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAING4ciuYkiTBBwhcgaHao+IoNxy0RxOJAw7aoF4gJ6yV root@desktop";
  me = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA8WKB45Qb5CqZPlE7LWKjkaCikJbjA87sVQwJWDTAB4 konjevicbojan1@gmail.com";
in {
  "user-password.age".publicKeys = [desktop me];
  "cachix-token.age".publicKeys = [desktop me];
  "ssh-private-key.age".publicKeys = [desktop me];
}
