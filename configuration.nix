# Generated from the Ubuntu 22.04 machine, 2026-08-29.
# On a fresh NixOS install: keep the installer's hardware-configuration.nix,
# drop this file in as /etc/nixos/configuration.nix, then:
#   sudo nixos-rebuild switch
{ config, pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix              # generated per machine - never copy this one
    <home-manager/nixos>                      # see setup note below
  ];

  home-manager.useGlobalPkgs = true;
  home-manager.useUserPackages = true;
  home-manager.users.yuridesktop = import ./home.nix;

  # ---------- boot ----------
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # ---------- host / network ----------
  networking.hostName = "nixos";               # as set by the installer
  networking.networkmanager.enable = true;

  # ---------- locale (mirrors your en_US + ru_RU split) ----------
  time.timeZone = "Europe/Moscow";
  i18n.defaultLocale = "en_US.UTF-8";
  i18n.extraLocaleSettings = {
    LC_NUMERIC = "ru_RU.UTF-8";
    LC_TIME    = "ru_RU.UTF-8";
  };

  # ---------- GNOME on Wayland ----------
  services.xserver.enable = true;
  services.xserver.xkb.layout = "us,ru";
  services.xserver.xkb.options = "grp:alt_shift_toggle";
  services.displayManager.gdm.enable = true;
  services.desktopManager.gnome.enable = true;

  # ---------- audio ----------
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };

  # ---------- file sync ----------
  # Replicates ~/repo/books with the Ubuntu desktop. Both machines keep a
  # full, ordinary copy - nothing is mounted or symlinked.
  services.syncthing = {
    enable = true;
    user = "yuridesktop";
    group = "users";
    dataDir = "/home/yuridesktop";
    configDir = "/home/yuridesktop/.config/syncthing";
    openDefaultPorts = true;      # 22000 tcp/udp sync, 21027/udp LAN discovery

    # Make this file authoritative: devices/folders removed here are removed
    # from Syncthing too, instead of lingering from the web UI.
    overrideDevices = true;
    overrideFolders = true;

    settings = {
      devices.ubuntu-desktop.id =
        "MLXERZC-QQLMTE3-BQXGHG6-24XAAZR-B7UKLP7-ON2RMM5-NQBDWRS-CJCT6QP";

      folders.books = {
        path = "/home/yuridesktop/repo/books";
        devices = [ "ubuntu-desktop" ];

        # Start one-way: Ubuntu is the source of truth, this machine only
        # receives. Nothing you do here can delete a book on Ubuntu.
        # Change to "sendreceive" once you trust it.
        type = "receiveonly";

        versioning = {
          type = "simple";
          params.keep = "5";      # deleted/changed files kept in .stversions
        };
      };
    };
  };

  # ---------- ssh ----------
  services.openssh = {
    enable = true;                      # opens port 22 in the firewall automatically
    settings = {
      PasswordAuthentication = false;   # key-only; the key is declared on the user below
      PermitRootLogin = "no";
    };
  };

  # mDNS, so this box is reachable as `nixos.local` without chasing DHCP leases
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    publish = {
      enable = true;
      addresses = true;
      workstation = true;
    };
  };

  # ---------- misc services ----------
  services.printing.enable = true;
  services.flatpak.enable = true;                # you have com.cdnex.ejx
  programs.gnupg.agent.enable = true;

  # ---------- user ----------
  users.users.yuridesktop = {
    isNormalUser = true;
    description = "Ivan";
    extraGroups = [ "wheel" "networkmanager" "video" "audio" ];
    shell = pkgs.bash;
    openssh.authorizedKeys.keys = [
      # ubuntu-desktop (192.168.0.107)
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIECbpIHIwBlUH93dvm+O/IZbUSASdwffhtQum58VWuKS yuri@ubuntu-desktop"
    ];
  };

  nixpkgs.config.allowUnfree = true;             # google-chrome

  # ---------- packages ----------
  environment.systemPackages = with pkgs; [
    # editors / terminal / shell  (was: cargo-installed)
    helix alacritty zellij yazi zoxide

    # cli tools  (was: apt)
    ripgrep fd jq tree xclip p7zip graphviz imagemagick
    poppler-utils ffmpeg ffmpegthumbnailer git gh

    # C/C++ toolchain  (was: build-essential, gcc-12, clangd-15, bear)
    gcc cmake pkg-config gnumake
    clang-tools            # provides clangd + clang-format
    bear gdb lldb
    protobuf

    # graphics / vulkan  (for your vulkano + graphics-book projects)
    vulkan-tools vulkan-loader vulkan-validation-layers shaderc
    glslang renderdoc

    # rust  - see note below, prefer devShells per project
    rustup

    # vpn - packaged locally, not in nixpkgs (see pkgs/adguardvpn-cli.nix)
    (callPackage ./pkgs/adguardvpn-cli.nix { })

    # other
    python3 wireshark marksman
    firefox thunderbird foliate
    # google-chrome moved to home.nix (programs.google-chrome, with extensions)
  ];

  # ---------- graphics: NVIDIA GeForce RTX 4060 (AD107, Ada Lovelace) ----------
  hardware.graphics = {
    enable = true;
    enable32Bit = true;          # Steam, wine, some Vulkan samples
  };

  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.nvidia = {
    modesetting.enable = true;   # required for Wayland/GNOME
    nvidiaSettings = true;

    # Ada is Turing-or-newer, so the open kernel modules are the right choice.
    # This option has no default - leaving it unset produces a build warning.
    open = true;

    package = config.boot.kernelPackages.nvidiaPackages.stable;

    powerManagement.enable = false;   # desktop; enable only if you suspend a lot
  };

  programs.wireshark.enable = true;              # sets up the wireshark group

  # Never change this after install - it is not a "latest version" knob.
  # Set it to the NixOS release you first installed.
  system.stateVersion = "26.05";
}
