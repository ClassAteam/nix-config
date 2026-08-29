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
  home-manager.users.yuri = import ./home.nix;

  # ---------- boot ----------
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # ---------- host / network ----------
  networking.hostName = "yuri-laptop";          # pick a name per machine
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

  # ---------- misc services ----------
  services.printing.enable = true;
  services.flatpak.enable = true;                # you have com.cdnex.ejx
  programs.gnupg.agent.enable = true;

  # ---------- user ----------
  users.users.yuri = {
    isNormalUser = true;
    description = "Ivan";
    extraGroups = [ "wheel" "networkmanager" "video" "audio" ];
    shell = pkgs.bash;
  };

  nixpkgs.config.allowUnfree = true;             # google-chrome

  # ---------- packages ----------
  environment.systemPackages = with pkgs; [
    # editors / terminal / shell  (was: cargo-installed)
    helix alacritty zellij yazi zoxide

    # cli tools  (was: apt)
    ripgrep fd jq tree xclip p7zip graphviz imagemagick
    poppler_utils ffmpeg ffmpegthumbnailer git gh

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
