# home-manager module: your dotfiles + user-level environment.
# Config files are referenced from ../configs, so this repo stays the
# single source of truth - edit the .toml files as normal, rebuild, done.
{ config, pkgs, ... }:
{
  home.username = "yuri";
  home.homeDirectory = "/home/yuri";

  # ---------- dotfiles: linked verbatim from ../configs ----------
  # No translation into Nix syntax - your existing files stay authoritative.
  home.file.".config/helix/config.toml".source       = ./dotfiles/config.toml;
  home.file.".config/helix/languages.toml".source    = ./dotfiles/languages.toml;
  home.file.".config/alacritty/alacritty.toml".source = ./dotfiles/alacritty.toml;
  home.file.".config/zellij/config.kdl".source       = ./dotfiles/config.kdl;
  home.file.".config/yazi/yazi.toml".source          = ./dotfiles/yazi.toml;
  home.file.".gdbinit".source                        = ./dotfiles/gdb/gdbinit;

  # ---------- bash ----------
  programs.bash = {
    enable = true;
    enableCompletion = true;

    historyControl = [ "ignoredups" "ignorespace" ];
    historySize = 10000;

    shellAliases = {
      ll = "ls -alF";
      la = "ls -A";
      l  = "ls -CF";
      ls = "ls --color=auto";
      grep = "grep --color=auto";
      # NOTE: your Ubuntu bashrc had `alias fd=find`, which shadowed the real
      # fd. Dropped - `fd` here is the actual fd tool. Re-add if you meant it.
    };

    sessionVariables = {
      EDITOR = "hx";
      # HELIX_RUNTIME deliberately NOT set - see note in the answer.
    };

    # yazi wrapper: cd to the directory you exited in
    initExtra = ''
      function y() {
        local tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
        yazi "$@" --cwd-file="$tmp"
        if cwd="$(cat -- "$tmp")" && [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
          builtin cd -- "$cwd"
        fi
        rm -f -- "$tmp"
      }
    '';
  };

  programs.zoxide = {
    enable = true;
    enableBashIntegration = true;   # replaces: eval "$(zoxide init bash)"
  };

  programs.git = {
    enable = true;
    userName  = "Ivan";
    userEmail = "royal_88@mail.ru";
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;       # auto-enter per-project devShells
  };

  home.stateVersion = "25.05";
}
