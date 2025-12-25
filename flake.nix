{
  description = "Static Erlang/OTP and Elixir built with musl libc";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    flake-utils.url = "github:numtide/flake-utils";
    devenv.url = "github:cachix/devenv";
  };

  outputs = { self, nixpkgs, flake-utils, devenv }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        # Standard pkgs for development tools
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ ];
        };

        # Static musl-based pkgs for building static binaries
        pkgsStatic = import nixpkgs {
          inherit system;
          crossSystem = {
            config = "x86_64-unknown-linux-musl";
            isStatic = true;
          };
        };

        # Alternative: use pkgsCross.musl64.pkgsStatic
        pkgsMuslStatic = pkgs.pkgsCross.musl64.pkgsStatic;

        # Import our static derivations
        staticErlang = import ./nix/static-erlang.nix {
          inherit pkgs;
          pkgsStatic = pkgsMuslStatic;
        };

        staticElixir = import ./nix/static-elixir.nix {
          inherit pkgs;
          pkgsStatic = pkgsMuslStatic;
          erlang = staticErlang;
        };

      in
      {
        packages = {
          static-erlang = staticErlang;
          static-elixir = staticElixir;
          default = staticElixir;

          # Convenience package that bundles both
          static-beam = pkgs.symlinkJoin {
            name = "static-beam";
            paths = [ staticErlang staticElixir ];
          };
        };

        # Development shell with build tools
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            # Nix tools
            nixpkgs-fmt
            nil

            # Build tools
            gnumake
            autoconf
            automake
            libtool

            # For testing
            file
            patchelf

            # Docker for verification
            docker

            # Standard Erlang/Elixir for development
            erlang
            elixir

            # Hex and rebar for Elixir projects
            hex
            rebar3
          ];

          shellHook = ''
            echo "Static BEAM Development Environment"
            echo "===================================="
            echo ""
            echo "Available commands:"
            echo "  nix build .#static-erlang  - Build static Erlang/OTP"
            echo "  nix build .#static-elixir  - Build static Elixir"
            echo "  nix build .#static-beam    - Build both"
            echo ""
            echo "  ./scripts/build.sh         - Build static BEAM"
            echo "  ./scripts/verify.sh        - Verify binaries are static"
            echo ""
          '';
        };

        # Devenv-based shell (alternative)
        devShells.devenv = devenv.lib.mkShell {
          inherit pkgs;
          inputs = { inherit nixpkgs; };
          modules = [ ./devenv.nix ];
        };
      }
    );

  nixConfig = {
    extra-substituters = [
      "https://cache.nixos.org"
      "https://devenv.cachix.org"
    ];
    extra-trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
      "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw="
    ];
  };
}
