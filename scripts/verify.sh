#!/usr/bin/env bash
# Verify that BEAM binaries are statically linked
#
# Usage:
#   ./scripts/verify.sh [path]
#
# Examples:
#   ./scripts/verify.sh              # Verify ./result
#   ./scripts/verify.sh /path/to/beam  # Verify specific path

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}[INFO]${NC} $*"
}

log_success() {
    echo -e "${GREEN}[PASS]${NC} $*"
}

log_warning() {
    echo -e "${YELLOW}[WARN]${NC} $*"
}

log_error() {
    echo -e "${RED}[FAIL]${NC} $*"
}

# Track verification results
TOTAL_CHECKS=0
PASSED_CHECKS=0
FAILED_CHECKS=0

check_binary() {
    local binary="$1"
    local name="${2:-$(basename "$binary")}"

    ((TOTAL_CHECKS++))

    if [ ! -f "$binary" ]; then
        log_error "$name: File not found"
        ((FAILED_CHECKS++))
        return 1
    fi

    if [ ! -x "$binary" ]; then
        log_warning "$name: Not executable"
    fi

    echo ""
    echo "Checking: $name"
    echo "Path: $binary"
    echo ""

    # Check with 'file' command
    local file_output
    file_output=$(file "$binary" 2>&1)
    echo "  file: $file_output"

    local is_static=false

    # Check if statically linked using 'file'
    if echo "$file_output" | grep -qi "statically linked"; then
        log_success "  file reports: statically linked"
        is_static=true
    elif echo "$file_output" | grep -qi "static"; then
        log_success "  file reports: static"
        is_static=true
    fi

    # Check with 'ldd' command
    local ldd_output
    if command -v ldd &> /dev/null; then
        ldd_output=$(ldd "$binary" 2>&1 || true)
        echo "  ldd: $(echo "$ldd_output" | head -1)"

        if echo "$ldd_output" | grep -qi "not a dynamic executable"; then
            log_success "  ldd reports: not a dynamic executable"
            is_static=true
        elif echo "$ldd_output" | grep -qi "statically linked"; then
            log_success "  ldd reports: statically linked"
            is_static=true
        elif echo "$ldd_output" | grep -q "libc.so\|libdl.so\|libpthread.so"; then
            log_error "  ldd reports: dynamically linked to glibc"
            is_static=false
        fi
    fi

    # Check with 'readelf' if available
    if command -v readelf &> /dev/null; then
        local interp
        interp=$(readelf -l "$binary" 2>/dev/null | grep "interpreter" || true)
        if [ -n "$interp" ]; then
            echo "  interpreter: $interp"
            if echo "$interp" | grep -q "ld-linux\|ld.so"; then
                log_warning "  Has dynamic linker reference"
                is_static=false
            fi
        else
            log_success "  No interpreter (static)"
            is_static=true
        fi
    fi

    # Check for musl
    if command -v strings &> /dev/null; then
        if strings "$binary" 2>/dev/null | grep -qi "musl"; then
            log_success "  Built with musl libc"
        fi
    fi

    if $is_static; then
        log_success "$name is statically linked!"
        ((PASSED_CHECKS++))
        return 0
    else
        log_error "$name is NOT statically linked"
        ((FAILED_CHECKS++))
        return 1
    fi
}

verify_beam_dir() {
    local beam_dir="$1"

    echo ""
    echo "╔══════════════════════════════════════════════════════════════════╗"
    echo "║              Static BEAM Verification                            ║"
    echo "╚══════════════════════════════════════════════════════════════════╝"
    echo ""
    echo "Verifying: $beam_dir"
    echo ""

    # Find key binaries to check
    local binaries_to_check=()

    # Erlang binaries
    if [ -d "$beam_dir/lib/erlang" ]; then
        log_info "Found Erlang installation"

        # beam.smp is the main BEAM VM
        local beam_smp
        beam_smp=$(find "$beam_dir/lib/erlang" -name "beam.smp" -type f 2>/dev/null | head -1)
        if [ -n "$beam_smp" ]; then
            binaries_to_check+=("$beam_smp:beam.smp")
        fi

        # erl_child_setup
        local erl_child
        erl_child=$(find "$beam_dir/lib/erlang" -name "erl_child_setup" -type f 2>/dev/null | head -1)
        if [ -n "$erl_child" ]; then
            binaries_to_check+=("$erl_child:erl_child_setup")
        fi

        # erlexec
        local erlexec
        erlexec=$(find "$beam_dir/lib/erlang" -name "erlexec" -type f 2>/dev/null | head -1)
        if [ -n "$erlexec" ]; then
            binaries_to_check+=("$erlexec:erlexec")
        fi

        # inet_gethost
        local inet_gethost
        inet_gethost=$(find "$beam_dir/lib/erlang" -name "inet_gethost" -type f 2>/dev/null | head -1)
        if [ -n "$inet_gethost" ]; then
            binaries_to_check+=("$inet_gethost:inet_gethost")
        fi
    fi

    # Direct bin/ binaries
    if [ -d "$beam_dir/bin" ]; then
        for bin in erl erlc escript dialyzer; do
            if [ -f "$beam_dir/bin/$bin" ] && [ -x "$beam_dir/bin/$bin" ]; then
                # Check if it's a wrapper script or binary
                if file "$beam_dir/bin/$bin" | grep -q "ELF"; then
                    binaries_to_check+=("$beam_dir/bin/$bin:$bin")
                fi
            fi
        done
    fi

    if [ ${#binaries_to_check[@]} -eq 0 ]; then
        log_error "No BEAM binaries found in $beam_dir"
        echo ""
        echo "Expected structure:"
        echo "  $beam_dir/lib/erlang/erts-*/bin/beam.smp"
        echo "  $beam_dir/bin/erl"
        exit 1
    fi

    # Check each binary
    for entry in "${binaries_to_check[@]}"; do
        local path="${entry%%:*}"
        local name="${entry##*:}"
        check_binary "$path" "$name" || true
    done

    # Summary
    echo ""
    echo "════════════════════════════════════════════════════════════════════"
    echo "                         SUMMARY"
    echo "════════════════════════════════════════════════════════════════════"
    echo ""
    echo "Total checks:  $TOTAL_CHECKS"
    echo -e "Passed:        ${GREEN}$PASSED_CHECKS${NC}"
    echo -e "Failed:        ${RED}$FAILED_CHECKS${NC}"
    echo ""

    if [ "$FAILED_CHECKS" -eq 0 ]; then
        log_success "All binaries are statically linked!"
        echo ""
        echo "The BEAM binaries should work on any Linux distribution including:"
        echo "  - Debian/Ubuntu"
        echo "  - Alpine Linux"
        echo "  - BusyBox"
        echo "  - Scratch containers"
        return 0
    else
        log_error "Some binaries are not statically linked"
        echo ""
        echo "This might cause portability issues on minimal Linux distributions."
        return 1
    fi
}

# Quick test with a minimal container
test_in_container() {
    local beam_dir="$1"
    local container_image="${2:-busybox:musl}"

    log_info "Testing in $container_image container..."

    if ! command -v docker &> /dev/null; then
        log_warning "Docker not available, skipping container test"
        return 0
    fi

    # Find beam.smp
    local beam_smp
    beam_smp=$(find "$beam_dir" -name "beam.smp" -type f 2>/dev/null | head -1)

    if [ -z "$beam_smp" ]; then
        log_warning "beam.smp not found, skipping container test"
        return 0
    fi

    # Test in container
    if docker run --rm -v "$beam_smp:/beam.smp:ro" "$container_image" /beam.smp -version 2>&1 | head -5; then
        log_success "Binary works in $container_image!"
    else
        log_error "Binary failed in $container_image"
    fi
}

# Main
main() {
    local beam_dir="${1:-}"

    # If no path provided, look for result symlink
    if [ -z "$beam_dir" ]; then
        if [ -L "$PROJECT_ROOT/result" ]; then
            beam_dir=$(readlink -f "$PROJECT_ROOT/result")
        else
            echo "Usage: $0 [path-to-beam-installation]"
            echo ""
            echo "Examples:"
            echo "  $0 ./result"
            echo "  $0 /nix/store/xxx-static-erlang"
            exit 1
        fi
    fi

    # Resolve symlinks
    beam_dir=$(readlink -f "$beam_dir")

    if [ ! -d "$beam_dir" ]; then
        log_error "Directory not found: $beam_dir"
        exit 1
    fi

    verify_beam_dir "$beam_dir"

    # Optional: test in container
    if [ "${TEST_IN_CONTAINER:-false}" = "true" ]; then
        echo ""
        test_in_container "$beam_dir" "busybox:musl"
        test_in_container "$beam_dir" "alpine:3.19"
        test_in_container "$beam_dir" "debian:bookworm-slim"
    fi
}

main "$@"
