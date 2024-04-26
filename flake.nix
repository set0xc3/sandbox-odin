{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = {nixpkgs, ...} @ inputs: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
  in {
    devShells.${system}.default = pkgs.mkShell {
      buildInputs = [
        pkgs.odin
        pkgs.SDL2
        pkgs.libGL
        pkgs.xorg.libX11
      ];

      # shellHook = ''
      #   exec $SHELL
      # '';
    };
  };
}
