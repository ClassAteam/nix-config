# nix-config

Declarative NixOS system + user environment. Migrated from an Ubuntu 22.04
machine (GNOME/Wayland, UEFI) on 2026-08-29.

## Layout

    configuration.nix   system: boot, locale, GNOME, services, system packages
    home.nix            user: dotfiles, bash, git, direnv (home-manager)
    dotfiles/           helix, alacritty, zellij, yazi, gdb configs (linked verbatim)

`dotfiles/` files are linked into place by `home.nix`, so they stay editable as
ordinary .toml/.kdl files. Edit, rebuild, done - no translation into Nix syntax.

## Deploying to a fresh NixOS machine

    # a fresh NixOS install has no git yet - borrow one for the clone
    nix-shell -p git --run 'git clone https://github.com/ClassAteam/nix-config ~/repo/nix-config'
    cd ~/repo/nix-config

    # 1. hardware-configuration.nix is generated per machine - keep the local one
    sudo cp /etc/nixos/hardware-configuration.nix .

    # 2. home-manager channel (release MUST match the NixOS release)
    sudo nix-channel --add \
      https://github.com/nix-community/home-manager/archive/release-26.05.tar.gz home-manager
    sudo nix-channel --update

    # 3. point NixOS at this repo
    sudo mv /etc/nixos/configuration.nix /etc/nixos/configuration.nix.orig
    sudo ln -s ~/repo/nix-config/configuration.nix /etc/nixos/configuration.nix

    # 4. build
    sudo nixos-rebuild switch

## Per-machine bits

Change these when adding a host:

- `networking.hostName` in configuration.nix
- `hardware-configuration.nix` - regenerate, never copy between machines
  (`nixos-generate-config --show-hardware-config`)

## If a rebuild fails

Nothing is applied until the build succeeds, so a broken config cannot break a
running system. To back out an applied generation:

    sudo nixos-rebuild switch --rollback

or pick an older generation from the boot menu.

## Not yet done

- per-project `flake.nix` devShells for the Rust/Vulkan projects (replaces rustup)
- `nix flake` conversion, once channels start to feel limiting
