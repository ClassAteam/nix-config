{
  description = "Ivan's NixOS machines: desktop (nixos) and vps-relay (Fornex, Germany)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, home-manager, disko, ... }: {
    nixosConfigurations = {
      # The NixOS desktop. GNOME, NVIDIA, dev toolchain, home-manager.
      desktop = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/desktop/configuration.nix
          home-manager.nixosModules.home-manager
          {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
            home-manager.users.yuridesktop = import ./home.nix;
          }
        ];
      };

      # The Fornex VPS (Germany) - a minimal SSH relay for reaching the
      # desktop/laptop over mobile networks. No GUI, no home-manager.
      vps-relay = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          disko.nixosModules.disko
          ./hosts/vps-relay/configuration.nix
          ./hosts/vps-relay/disko.nix
        ];
      };
    };
  };
}
