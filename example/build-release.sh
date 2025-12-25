#!/usr/bin/env bash
# Build a static release of the example application
#
# This script demonstrates how to build an Elixir release
# using the statically-linked BEAM VM from our Nix build.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}[INFO]${NC} $*"; }
log_success() { echo -e "${GREEN}[SUCCESS]${NC} $*"; }
log_error() { echo -e "${RED}[ERROR]${NC} $*"; }

# Find static ERTS
find_static_erts() {
    # Check environment variable first
    if [ -n "${STATIC_ERTS_PATH:-}" ]; then
        echo "$STATIC_ERTS_PATH"
        return
    fi

    # Check for Nix build result
    if [ -L "$PROJECT_ROOT/result" ]; then
        local result_path
        result_path=$(readlink -f "$PROJECT_ROOT/result")
        if [ -d "$result_path/lib/erlang" ]; then
            echo "$result_path/lib/erlang"
            return
        fi
    fi

    # Build static Erlang if not found
    log_info "Static ERTS not found. Building..."
    pushd "$PROJECT_ROOT" > /dev/null
    nix build .#static-erlang -L
    popd > /dev/null

    local result_path
    result_path=$(readlink -f "$PROJECT_ROOT/result")
    echo "$result_path/lib/erlang"
}

main() {
    echo ""
    echo "╔══════════════════════════════════════════════════════════════════╗"
    echo "║         Building Static Elixir Release                           ║"
    echo "╚══════════════════════════════════════════════════════════════════╝"
    echo ""

    cd "$SCRIPT_DIR"

    # Find static ERTS
    STATIC_ERTS=$(find_static_erts)
    log_info "Using static ERTS from: $STATIC_ERTS"

    # Verify ERTS exists
    if [ ! -d "$STATIC_ERTS" ]; then
        log_error "Static ERTS not found at $STATIC_ERTS"
        exit 1
    fi

    # Export for mix.exs
    export STATIC_ERTS_PATH="$STATIC_ERTS"

    # Build the release
    log_info "Getting dependencies..."
    MIX_ENV=prod mix deps.get --only prod

    log_info "Compiling..."
    MIX_ENV=prod mix compile

    log_info "Building release..."
    MIX_ENV=prod mix release --overwrite

    log_success "Release built successfully!"
    echo ""
    echo "Release location: _build/prod/rel/static_beam_example"
    echo ""
    echo "To run the release:"
    echo "  _build/prod/rel/static_beam_example/bin/static_beam_example start"
    echo ""
    echo "To test in Docker:"
    echo "  docker run --rm -v \$(pwd)/_build/prod/rel/static_beam_example:/app busybox:musl /app/bin/static_beam_example eval 'StaticBeamExample.hello()'"
    echo ""
}

main "$@"
