{ pkgs, lib, config, inputs, ... }:

{
  # Enable devenv features
  dotenv.enable = true;

  # Set project name
  name = "static-beam";

  # Environment variables
  env = {
    # Nix-related
    NIX_CONFIG = "experimental-features = nix-command flakes";

    # Project paths
    STATIC_BEAM_ROOT = builtins.toString ./.;
  };

  # Development packages
  packages = with pkgs; [
    # Nix development
    nixpkgs-fmt
    nil
    nix-tree
    nix-diff

    # Build tools
    gnumake
    autoconf
    automake
    libtool
    m4
    perl

    # Verification tools
    file
    patchelf
    binutils  # for ldd, objdump, etc.

    # Docker for testing
    docker
    docker-compose

    # Git
    git

    # Shell utilities
    jq
    yq
    ripgrep
    fd

    # Documentation
    mdbook
  ];

  # Standard Erlang/Elixir for development (not static)
  # Use this for regular development, switch to static for releases
  languages.erlang = {
    enable = true;
    package = pkgs.erlang;
  };

  languages.elixir = {
    enable = true;
    package = pkgs.elixir;
  };

  # Scripts available in the dev shell
  scripts = {
    build-static-erlang = {
      exec = ''
        echo "Building static Erlang/OTP..."
        nix build .#static-erlang -L
        echo "Done! Output in ./result"
      '';
      description = "Build static Erlang/OTP with musl";
    };

    build-static-elixir = {
      exec = ''
        echo "Building static Elixir..."
        nix build .#static-elixir -L
        echo "Done! Output in ./result"
      '';
      description = "Build static Elixir with musl";
    };

    build-static-beam = {
      exec = ''
        echo "Building static BEAM (Erlang + Elixir)..."
        nix build .#static-beam -L
        echo "Done! Output in ./result"
      '';
      description = "Build both static Erlang and Elixir";
    };

    verify-static = {
      exec = ''
        ./scripts/verify.sh "$@"
      '';
      description = "Verify binaries are statically linked";
    };

    test-docker = {
      exec = ''
        echo "Building and testing Docker images..."
        docker build -t static-beam-test .
        docker run --rm static-beam-test
      '';
      description = "Test static binaries in Docker containers";
    };

    clean = {
      exec = ''
        echo "Cleaning build artifacts..."
        rm -rf result result-*
        echo "Done!"
      '';
      description = "Remove build outputs";
    };
  };

  # Pre-commit hooks
  pre-commit.hooks = {
    nixpkgs-fmt.enable = true;
    shellcheck.enable = true;
  };

  # Shell hook
  enterShell = ''
    echo ""
    echo "╔══════════════════════════════════════════════════════════════════╗"
    echo "║              Static BEAM Development Environment                  ║"
    echo "╚══════════════════════════════════════════════════════════════════╝"
    echo ""
    echo "Available commands:"
    echo "  build-static-erlang   - Build static Erlang/OTP"
    echo "  build-static-elixir   - Build static Elixir"
    echo "  build-static-beam     - Build both static Erlang and Elixir"
    echo "  verify-static         - Verify binaries are static"
    echo "  test-docker           - Test in Docker containers"
    echo "  clean                 - Remove build artifacts"
    echo ""
    echo "Nix commands:"
    echo "  nix build .#static-erlang"
    echo "  nix build .#static-elixir"
    echo "  nix build .#static-beam"
    echo ""
    echo "Erlang version: $(erl -eval 'erlang:display(erlang:system_info(otp_release)), halt().' -noshell 2>/dev/null || echo 'N/A')"
    echo "Elixir version: $(elixir --version 2>/dev/null | head -1 || echo 'N/A')"
    echo ""
  '';

  # Process supervision (optional)
  # Useful for running example app during development
  processes = {
    # example-app.exec = "cd example && iex -S mix";
  };

  # Container support (for testing)
  containers = {
    # Define containers for testing if needed
  };
}
