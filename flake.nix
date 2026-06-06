{
  description = "LazyDelver";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    isaacApi = {
      url = "github:filloax/isaac-api-autocomplete-lua";
      flake = false;
    };
  };

  outputs = { nixpkgs, flake-utils, ... }@inputs:
    flake-utils.lib.eachDefaultSystem (system: 
      let
        pkgs = import nixpkgs { inherit system; };
      in {
        devShells.default = pkgs.mkShell {
          shellHook = ''
            ln -sfn ${inputs.isaacApi} .isaac-api
          '';
        };
      }
    );
}
