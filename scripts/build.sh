#!/usr/bin/env bash
# Build static BEAM (Erlang/OTP and Elixir) with musl libc
#
# Usage:
#   ./scripts/build.sh [erlang|elixir|all]
#
# Examples:
#   ./scripts/build.sh erlang   # Build only static Erlang
#   ./scripts/build.sh elixir   # Build only static Elixir
#   ./scripts/build.sh all      # Build both (default)
#   ./scripts/build.sh          # Same as 'all'

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $*"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $*"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $*"
}

print_banner() {
    echo ""
    echo "╔══════════════════════════════════════════════════════════════════╗"
    echo "║           Static BEAM Builder (musl libc)                        ║"
    echo "╚══════════════════════════════════════════════════════════════════╝"
    echo ""
}

check_nix() {
    if ! command -v nix &> /dev/null; then
        log_error "Nix is not installed. Please install Nix first:"
        echo "  curl -L https://nixos.org/nix/install | sh"
        exit 1
    fi

    # Check for flakes support
    if ! nix --version | grep -q "2\.[4-9]\|2\.[1-9][0-9]"; then
        log_warning "Nix version might not support flakes. Consider upgrading."
    fi
}

build_erlang() {
    log_info "Building static Erlang/OTP..."
    echo ""

    cd "$PROJECT_ROOT"

    # Build with logging
    if nix build .#static-erlang -L --show-trace; then
        log_success "Static Erlang built successfully!"

        # Show output location
        if [ -L "$PROJECT_ROOT/result" ]; then
            RESULT_PATH=$(readlink -f "$PROJECT_ROOT/result")
            echo ""
            echo "Output: $RESULT_PATH"
            echo ""
            echo "Key binaries:"
            find "$RESULT_PATH/bin" -type f -executable 2>/dev/null | head -10 || true
        fi
    else
        log_error "Failed to build static Erlang"
        exit 1
    fi
}

build_elixir() {
    log_info "Building static Elixir..."
    echo ""

    cd "$PROJECT_ROOT"

    # Build with logging
    if nix build .#static-elixir -L --show-trace; then
        log_success "Static Elixir built successfully!"

        # Show output location
        if [ -L "$PROJECT_ROOT/result" ]; then
            RESULT_PATH=$(readlink -f "$PROJECT_ROOT/result")
            echo ""
            echo "Output: $RESULT_PATH"
            echo ""
            echo "Key binaries:"
            ls -la "$RESULT_PATH/bin/" 2>/dev/null | head -10 || true
        fi
    else
        log_error "Failed to build static Elixir"
        exit 1
    fi
}

build_all() {
    log_info "Building static BEAM (Erlang + Elixir)..."
    echo ""

    cd "$PROJECT_ROOT"

    # Build combined package
    if nix build .#static-beam -L --show-trace; then
        log_success "Static BEAM built successfully!"

        if [ -L "$PROJECT_ROOT/result" ]; then
            RESULT_PATH=$(readlink -f "$PROJECT_ROOT/result")
            echo ""
            echo "Output: $RESULT_PATH"
            echo ""

            # Run verification
            log_info "Running verification..."
            "$SCRIPT_DIR/verify.sh" "$RESULT_PATH" || true
        fi
    else
        log_error "Failed to build static BEAM"
        exit 1
    fi
}

copy_to_output() {
    local output_dir="${1:-$PROJECT_ROOT/output}"

    if [ -L "$PROJECT_ROOT/result" ]; then
        log_info "Copying result to $output_dir..."
        rm -rf "$output_dir"
        cp -rL "$PROJECT_ROOT/result" "$output_dir"
        log_success "Copied to $output_dir"
    fi
}

print_usage() {
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  erlang    Build static Erlang/OTP only"
    echo "  elixir    Build static Elixir only"
    echo "  all       Build both Erlang and Elixir (default)"
    echo "  help      Show this help message"
    echo ""
    echo "Options:"
    echo "  --copy-to DIR   Copy result to specified directory"
    echo ""
    echo "Examples:"
    echo "  $0 erlang"
    echo "  $0 all --copy-to ./static-beam-dist"
}

# Main
main() {
    print_banner
    check_nix

    local command="${1:-all}"
    local copy_to=""

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            --copy-to)
                copy_to="$2"
                shift 2
                ;;
            erlang|elixir|all|help)
                command="$1"
                shift
                ;;
            *)
                log_error "Unknown argument: $1"
                print_usage
                exit 1
                ;;
        esac
    done

    case $command in
        erlang)
            build_erlang
            ;;
        elixir)
            build_elixir
            ;;
        all)
            build_all
            ;;
        help)
            print_usage
            exit 0
            ;;
        *)
            log_error "Unknown command: $command"
            print_usage
            exit 1
            ;;
    esac

    # Copy to output if requested
    if [ -n "$copy_to" ]; then
        copy_to_output "$copy_to"
    fi

    echo ""
    log_success "Build complete!"
    echo ""
    echo "Next steps:"
    echo "  1. Run './scripts/verify.sh' to verify binaries are static"
    echo "  2. Test in Docker: 'docker build -t test . && docker run --rm test'"
    echo ""
}

main "$@"
