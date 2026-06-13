{userConfig, ...}: {
  programs.zsh.shellAliases = {
    t = "thunar .";
    ngens = "sudo nix-env --list-generations --profile /nix/var/nix/profiles/system";
    vmi = "cd ${userConfig.dotfilesDir} && ./lib/iso/vm.sh install";
    vmr = "cd ${userConfig.dotfilesDir} && ./lib/iso/vm.sh run";
    postinstall = "cd ${userConfig.dotfilesDir} && nix run .#post-install";
    buildiso = "cd ${userConfig.dotfilesDir} && nix build .#iso";
  };

  programs.zsh.initExtra = ''
    flashiso() {
      local iso="${userConfig.dotfilesDir}/result/iso/nixos-custom-installer.iso"
      if [[ ! -f "$iso" ]]; then
        echo -e "\033[1;31m✗\033[0m  ISO not found, run buildiso first"
        return 1
      fi
      echo -e "\033[1;36mAvailable disks:\033[0m"
      lsblk -d -o NAME,SIZE,MODEL | grep -v loop
      echo -n $'\n\033[1mTarget device (e.g. /dev/sdb): \033[0m'
      read target
      echo -e "\n\033[1;31mWARNING: $target will be completely wiped\033[0m"
      echo -n $'\033[1mConfirm? (y/n): \033[0m'
      read confirm
      [[ $confirm == "y" ]] || { echo "Aborted."; return 1; }
      sudo dd if="$iso" of="$target" bs=4M status=progress conv=fsync
      echo -e "\033[1;32m✓\033[0m  Done — safe to remove drive."
    }
  '';
}
