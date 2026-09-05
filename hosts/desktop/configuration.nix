# Generated from the Ubuntu 22.04 machine, 2026-08-29.
# Deployed via the repo's flake.nix (nixosConfigurations.desktop), which also
# wires up home-manager and imports ../../home.nix - see ../../flake.nix and
# ../../README.md for the deploy commands.
{ config, pkgs, ... }:
{
  imports = [
    ./hardware-configuration.nix              # generated per machine - never copy this one
  ];

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
      devices.android-phone.id =
        "LNAQK4W-6RPYI7O-5WY4TGR-O4TAX3M-LILCZ2E-A5O3R3S-3QFH2DW-QA44HQH";

      folders.books = {
        path = "/home/yuridesktop/repo/books";
        devices = [ "ubuntu-desktop" "android-phone" ];

        # Two-way: books added or removed on either machine propagate to the
        # other. Deletions are recoverable from .stversions below.
        type = "sendreceive";

        versioning = {
          type = "simple";
          params.keep = "5";      # deleted/changed files kept in .stversions
        };
      };

      # Notes are edited on both machines, so this one is two-way.
      # NOTE: this includes .git. Syncthing and git coexist fine as long as you
      # don't run git operations on both machines at the same time - let a sync
      # settle before switching machines. GitHub remains the real backup.
      folders.mynotes = {
        path = "/home/yuridesktop/repo/mynotes";
        devices = [ "ubuntu-desktop" "android-phone" ];
        type = "sendreceive";

        versioning = {
          type = "simple";
          params.keep = "10";     # notes are small; keep more history
        };
      };
    };
  };

  # ---------- KDE Connect (via GSConnect, since this is GNOME not Plasma) ----------
  # Opens firewall ports 1714-1764 tcp/udp automatically and installs the
  # GNOME Shell extension. Still needs enabling once in the Extensions app
  # (or via `gnome-extensions enable gsconnect@andyholmes.github.io`) after
  # rebuild, then pair from the phone's KDE Connect app over the same LAN.
  programs.kdeconnect = {
    enable = true;
    package = pkgs.gnomeExtensions.gsconnect;
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

  # ---------- reverse SSH tunnel to vps-relay ----------
  # Holds port 2222 on the VPS open, forwarding back to this machine's :22 -
  # this is what makes the desktop reachable from mobile networks, via the
  # VPS, when direct/WireGuard connectivity is unreliable. See
  # mynotes/vps-relay-reference/ for the whole picture.
  #
  # Plain ssh + systemd Restart=always, not autossh - ServerAliveInterval
  # plus ExitOnForwardFailure already gets ssh to notice a dead connection
  # and exit, and systemd restarts it; autossh would just be a second layer
  # doing the same job.
  systemd.services.vps-relay-tunnel = {
    description = "Reverse SSH tunnel to vps-relay (VPS:2222 -> this machine:22)";
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    serviceConfig = {
      User = "yuridesktop";
      ExecStart = ''
        ${pkgs.openssh}/bin/ssh -N -T \
          -o ExitOnForwardFailure=yes \
          -o ServerAliveInterval=30 \
          -o ServerAliveCountMax=3 \
          -o StrictHostKeyChecking=yes \
          -R 0.0.0.0:2222:localhost:22 \
          tunnel@79.132.143.145
      '';
      Restart = "always";
      RestartSec = 5;
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

    # vpn - packaged locally, not in nixpkgs (see ../../pkgs/adguardvpn-cli.nix)
    (callPackage ../../pkgs/adguardvpn-cli.nix { })

    # other
    python3 wireshark marksman
    firefox thunderbird foliate telegram-desktop
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
