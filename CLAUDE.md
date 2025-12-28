# CLAUDE.md

This file provides guidance to Claude Code when working with this repository.

See [SPECKIT.md](SPECKIT.md) for full specification.

## Project Overview

Static BEAM builds fully static Erlang/OTP binaries using Alpine Linux and musl libc. The resulting binaries have zero dynamic dependencies and run on any Linux distribution.

**Key constraints**:
- Output must have NO dynamic links (`ldd` returns "not a dynamic executable")
- Use musl libc (Alpine Linux native)
- Release tags: `OTP-{version}` (e.g., `OTP-27.2`)
- Build for both amd64 and arm64

## Build Commands

```bash
# Build static Erlang (outputs to ./static-erlang/)
docker build --target erlang -o ./static-erlang .

# Build and run tests
docker build -t static-beam . && docker run --rm static-beam
```

## Usage

**Important**: Mount at `/opt/erlang` - paths are compiled in.

```bash
docker run --rm -v ./static-erlang:/opt/erlang debian:bookworm-slim \
  /opt/erlang/bin/erl -noshell -eval 'io:format("Hello!~n"), halt().'
```

## devenv Commands

```bash
devenv shell           # Enter development environment
sbeam build erlang     # Build static Erlang
sbeam verify           # Verify binaries are static
sbeam test             # Test in Docker containers
sbeam clean            # Remove build artifacts
```

## Architecture

- **Dockerfile**: Multi-stage Alpine build. Compiles Erlang/OTP from source with `LDFLAGS="-static"`, `--enable-static-nifs`, `--enable-static-drivers`. Exports via `docker build -o`.

- **devenv.nix**: Development environment with `sbeam` command wrapper.

- **.github/workflows/build.yml**: CI that builds, verifies static linking, and tests on Debian/Alpine/BusyBox.

## Key Files

| File | Purpose |
|------|---------|
| `Dockerfile` | Multi-stage static build |
| `devenv.nix` | Dev environment + sbeam command |
| `.github/workflows/build.yml` | CI/CD pipeline |

## Versions

- Erlang/OTP: 27.2
- Alpine: 3.21

## Known Limitations

- Must mount at `/opt/erlang` (compiled-in path)
- Elixir static build has SSL linking issues (WIP)

## Active Technologies
- Elixir 1.15+ (for demo app), YAML (for workflow) + Mix (Elixir build tool), GitHub Actions (001-e2e-test)
- N/A (stateless workflow) (001-e2e-test)

## Recent Changes
- 001-e2e-test: Added Elixir 1.15+ (for demo app), YAML (for workflow) + Mix (Elixir build tool), GitHub Actions
