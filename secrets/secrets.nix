let
  me = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIBgvB6yyzUZ0GUfyksOZHa6UDlnRGUUzHu0sAnNKDVbV konjevicbojan1@gmail.com";
in {
  "user-password.age".publicKeys = [me];
  "cachix-token.age".publicKeys = [me];
  "ssh-private-key.age".publicKeys = [me];
}
