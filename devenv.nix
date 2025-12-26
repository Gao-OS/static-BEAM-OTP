{ pkgs, lib, config, inputs, ... }:

let
  pkgs-stable = import inputs.nixpkgs-stable { system = pkgs.stdenv.system; };
  pkgs-unstable = import inputs.nixpkgs-unstable { system = pkgs.stdenv.system; };

  # Pin OTP version - update this when upgrading
  otpVersion = "28.0";
  elixirVersion = "1.18.3";
in
{
  # Environment variables
  env = {
    STATIC_BEAM_ROOT = builtins.toString ./.;
    OTP_VERSION = otpVersion;
    ELIXIR_VERSION = elixirVersion;
  };

  # Dependencies
  packages = with pkgs-stable; [
    # Nix tools
    nixpkgs-fmt
    nil

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
    binutils

    # Docker for testing
    docker

    # Shell utilities
    jq
    ripgrep
    fd
    figlet
    lolcat
  ];

  # Erlang/Elixir for development
  languages.erlang.enable = true;
  languages.erlang.package = pkgs-stable.beam28Packages.erlang;

  languages.elixir.enable = true;
  languages.elixir.package = pkgs-stable.beam28Packages.elixir;

  # Show help on entering environment
  enterShell = ''
    export STATIC_ERTS_PATH="$STATIC_BEAM_ROOT/result/lib/erlang"

    figlet -w 80 "Static BEAM" | lolcat
    echo ""
    echo "Target: OTP-$OTP_VERSION (Elixir $ELIXIR_VERSION)"
    echo ""
    echo "Commands:"
    echo "  sbeam build [erlang|elixir|all]  - Build static BEAM"
    echo "  sbeam verify [path]              - Verify binaries are static"
    echo "  sbeam test                       - Test in Docker containers"
    echo "  sbeam clean                      - Remove build artifacts"
    echo "  sbeam help                       - Show all commands"
    echo ""
  '';

  # sbeam command implementation
  scripts.sbeam.exec = ''
    set -e

    # Colors
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    BLUE='\033[0;34m'
    NC='\033[0m'

    log_info() { echo -e "''${BLUE}[INFO]''${NC} $*"; }
    log_success() { echo -e "''${GREEN}[SUCCESS]''${NC} $*"; }
    log_warning() { echo -e "''${YELLOW}[WARN]''${NC} $*"; }
    log_error() { echo -e "''${RED}[FAIL]''${NC} $*"; }

    _check_nix() {
      if ! command -v nix &> /dev/null; then
        log_error "Nix is not installed"
        exit 1
      fi
    }

    _build_erlang() {
      log_info "Building static Erlang/OTP with musl..."
      nix-build "$STATIC_BEAM_ROOT/nix/static-erlang.nix" -o "$STATIC_BEAM_ROOT/result"
      log_success "Static Erlang built: $STATIC_BEAM_ROOT/result"
    }

    _build_elixir() {
      log_info "Building static Elixir with musl..."
      nix-build "$STATIC_BEAM_ROOT/nix/static-elixir.nix" -o "$STATIC_BEAM_ROOT/result"
      log_success "Static Elixir built: $STATIC_BEAM_ROOT/result"
    }

    _verify_binary() {
      local binary="$1"
      local name="''${2:-$(basename "$binary")}"

      if [ ! -f "$binary" ]; then
        log_error "$name: File not found"
        return 1
      fi

      echo ""
      echo "Checking: $name"

      local file_output
      file_output=$(file "$binary" 2>&1)
      echo "  file: $file_output"

      local ldd_output
      ldd_output=$(ldd "$binary" 2>&1 || true)
      echo "  ldd: $(echo "$ldd_output" | head -1)"

      if echo "$file_output" | grep -qi "statically linked"; then
        log_success "$name is statically linked"
        return 0
      elif echo "$ldd_output" | grep -qi "not a dynamic executable"; then
        log_success "$name is statically linked"
        return 0
      else
        log_error "$name is NOT statically linked"
        return 1
      fi
    }

    _verify() {
      local beam_dir="''${1:-$STATIC_BEAM_ROOT/result}"

      if [ -L "$beam_dir" ]; then
        beam_dir=$(readlink -f "$beam_dir")
      fi

      if [ ! -d "$beam_dir" ]; then
        log_error "Directory not found: $beam_dir"
        exit 1
      fi

      echo ""
      echo "╔══════════════════════════════════════════════════════════════════╗"
      echo "║              Static BEAM Verification                            ║"
      echo "╚══════════════════════════════════════════════════════════════════╝"
      echo ""
      echo "Verifying: $beam_dir"

      local passed=0
      local failed=0

      # Find beam.smp
      local beam_smp
      beam_smp=$(find "$beam_dir" -name "beam.smp" -type f 2>/dev/null | head -1)
      if [ -n "$beam_smp" ]; then
        if _verify_binary "$beam_smp" "beam.smp"; then
          ((passed++))
        else
          ((failed++))
        fi
      fi

      # Find erlexec
      local erlexec
      erlexec=$(find "$beam_dir" -name "erlexec" -type f 2>/dev/null | head -1)
      if [ -n "$erlexec" ]; then
        if _verify_binary "$erlexec" "erlexec"; then
          ((passed++))
        else
          ((failed++))
        fi
      fi

      echo ""
      echo "════════════════════════════════════════════════════════════════════"
      echo "Passed: $passed  Failed: $failed"
      echo "════════════════════════════════════════════════════════════════════"

      if [ "$failed" -eq 0 ]; then
        log_success "All binaries are statically linked!"
      else
        log_error "Some binaries are not statically linked"
        exit 1
      fi
    }

    _test_docker() {
      log_info "Testing static BEAM in Docker containers..."

      if [ ! -L "$STATIC_BEAM_ROOT/result" ]; then
        log_error "No build found. Run 'sbeam build' first"
        exit 1
      fi

      # Copy result for Docker
      rm -rf "$STATIC_BEAM_ROOT/static-beam"
      cp -rL "$STATIC_BEAM_ROOT/result" "$STATIC_BEAM_ROOT/static-beam"

      log_info "Building test container..."
      docker build -t static-beam-test "$STATIC_BEAM_ROOT"

      log_info "Running tests..."
      docker run --rm static-beam-test

      log_success "Docker tests passed!"
    }

    _clean() {
      log_info "Cleaning build artifacts..."
      rm -rf "$STATIC_BEAM_ROOT/result" "$STATIC_BEAM_ROOT/result-"* "$STATIC_BEAM_ROOT/static-beam"
      log_success "Cleaned"
    }

    cmd="''${1:-help}"
    shift || true

    case "$cmd" in
      build)
        _check_nix
        target="''${1:-all}"
        case "$target" in
          erlang)
            _build_erlang
            ;;
          elixir)
            _build_elixir
            ;;
          all)
            _build_erlang
            ;;
          *)
            echo "Usage: sbeam build [erlang|elixir|all]"
            exit 1
            ;;
        esac
        ;;

      verify)
        _verify "$1"
        ;;

      test)
        _test_docker
        ;;

      clean)
        _clean
        ;;

      help|--help|-h)
        echo "sbeam - Static BEAM Build Tool"
        echo ""
        echo "Build Commands:"
        echo "  sbeam build [erlang|elixir|all]   Build static BEAM (default: all)"
        echo "  sbeam verify [path]               Verify binaries are static"
        echo "  sbeam test                        Test in Docker containers"
        echo ""
        echo "Maintenance:"
        echo "  sbeam clean                       Remove build artifacts"
        echo "  sbeam help                        Show this help"
        echo ""
        echo "Example workflow:"
        echo "  sbeam build erlang    # Build static Erlang/OTP"
        echo "  sbeam verify          # Verify it's static"
        echo "  sbeam test            # Test in Docker"
        ;;

      *)
        echo "Unknown command: $cmd"
        echo "Run 'sbeam help' for available commands"
        exit 1
        ;;
    esac
  '';
}
