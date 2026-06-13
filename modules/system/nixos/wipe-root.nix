{pkgs, ...}: let
  wipe-root-script = pkgs.writeShellApplication {
    name = "wipe-root";
    runtimeInputs = [
      pkgs.btrfs-progs
      pkgs.gnugrep
      pkgs.gawk
      pkgs.coreutils
      pkgs.util-linux
    ];
    text = ''
      echo "wipe-root: Starting root wipe..."

      MNT="$(mktemp -d)"
      mount -t btrfs -o subvolid=5 /dev/mapper/cryptroot "$MNT"

      if btrfs subvolume list "$MNT" | grep -q ' @blank$'; then
        echo "wipe-root: Deleting @ and all nested subvolumes..."

        NESTED="$(btrfs subvolume list -o "$MNT/@" \
          | awk '{print $NF}' \
          | sort -r)"

        if [ -n "$NESTED" ]; then
          while IFS= read -r sub; do
            echo "wipe-root: Deleting nested subvolume: $sub"
            btrfs subvolume delete "$MNT/$sub"
          done <<< "$NESTED"
        fi

        btrfs subvolume delete "$MNT/@"
        echo "wipe-root: Creating snapshot from @blank..."
        btrfs subvolume snapshot "$MNT/@blank" "$MNT/@"
        echo "wipe-root: Wipe complete."
      else
        echo "wipe-root: @blank not found, skipping wipe." >&2
      fi

      umount "$MNT"
      rmdir "$MNT"
    '';
  };
in {
  boot.initrd.supportedFilesystems = ["btrfs"];
  boot.initrd.systemd.enable = true;

  boot.initrd.systemd.storePaths = [
    "${wipe-root-script}/bin/wipe-root"
    "${pkgs.btrfs-progs}/bin/btrfs"
    "${pkgs.gnugrep}/bin/grep"
    "${pkgs.gawk}/bin/awk"
    "${pkgs.coreutils}/bin/test"
    "${pkgs.coreutils}/bin/sleep"
    "${pkgs.coreutils}/bin/mktemp"
    "${pkgs.coreutils}/bin/rmdir"
    "${pkgs.coreutils}/bin/sort"
    "${pkgs.util-linux}/bin/mount"
    "${pkgs.util-linux}/bin/umount"
  ];

  boot.initrd.systemd.services.wipe-root = {
    description = "Wipe / by restoring @blank btrfs snapshot";
    wantedBy = ["initrd.target"];
    after = ["systemd-cryptsetup@cryptroot.service"];
    wants = ["systemd-cryptsetup@cryptroot.service"];
    before = ["sysroot.mount" "initrd-root-fs.target"];
    unitConfig.DefaultDependencies = false;
    serviceConfig = {
      Type = "oneshot";
      ExecStart = "${wipe-root-script}/bin/wipe-root";
    };
  };
}
