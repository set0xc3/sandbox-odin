{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = {nixpkgs, ...}: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
  in {
    devShells.${system}.default = with pkgs;
      pkgs.mkShell {
        LD_LIBRARY_PATH = "$LD_LIBRARY_PATH:${
          pkgs.lib.makeLibraryPath [
            clang
            SDL2
            SDL2_ttf
            libGL
            xorg.libX11
          ]
        }";

        buildInputs = with pkgs; [
          odin
          clang
          SDL2
          SDL2_ttf
          libGL
          xorg.libX11
        ];
      };
  };
}
