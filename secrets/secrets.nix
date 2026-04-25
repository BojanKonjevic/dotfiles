let
  desktop = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGjvwL8jlVINhbylJgOG4ZUDIM6zcFtPkmBZpyTt+6UQ root@nixos";
  me = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIA8WKB45Qb5CqZPlE7LWKjkaCikJbjA87sVQwJWDTAB4 konjevicbojan1@gmail.com";
in {
  "cachix-token.age".publicKeys = [desktop me];
  "ssh-private-key.age".publicKeys = [desktop me];
}
