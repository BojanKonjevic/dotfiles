{...}: {
  fileSystems."/persist".neededForBoot = true;

  environment.persistence."/persist" = {
    hideMounts = true;

    directories = [
      {
        directory = "/etc/ssh";
        mode = "0700";
      }
      {
        directory = "/etc/secureboot";
        mode = "0700";
      }
      {
        directory = "/etc/NetworkManager/system-connections";
        mode = "0700";
      }
      {
        directory = "/var/lib/nixos";
        mode = "0755";
      }
      {
        directory = "/var/lib/bluetooth";
        mode = "0700";
      }
      {
        directory = "/var/lib/postgresql";
        mode = "0700";
      }
      {
        directory = "/var/lib/pipewire";
        mode = "0755";
      }
      {
        directory = "/var/lib/fwupd";
        mode = "0755";
      }
      {
        directory = "/var/db/sudo";
        mode = "0700";
      }
      {
        directory = "/var/cache/tuigreet";
        mode = "0755";
      }
      {
        directory = "/var/log/journal";
        mode = "2755";
      }
    ];

    files = [
      "/etc/machine-id"
      "/etc/adjtime"
      "/var/lib/systemd/random-seed"
    ];
  };
}
