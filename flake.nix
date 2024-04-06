{
  description = "Flake for building a Raspberry Pi Zero 2 SD image";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    deploy-rs.url = "github:serokell/deploy-rs";
  };

  outputs = {
    self,
    nixpkgs,
    deploy-rs,
  }:
    let
      cross = nixpkgs.legacyPackages.x86_64-linux.pkgsCross."aarch64-multiplatform";
    in
    {
    inherit cross;
    nixosConfigurations = {
      zero2w = nixpkgs.lib.nixosSystem {
        system = "aarch64-multiplatform";
        pkgs = cross;
        modules = [
          "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64.nix"
          ./zero2w.nix
        ];
      };
    };

  };
}
