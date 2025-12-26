# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Static BEAM builds fully static Erlang/OTP and Elixir binaries using Alpine Linux and musl libc. The resulting binaries have zero dynamic dependencies and run on any Linux distribution (Debian, Alpine, BusyBox, scratch containers).

## Commands

Enter development environment:
```bash
devenv shell
```

Build and verify static binaries:
```bash
sbeam build erlang      # Build static Erlang/OTP
sbeam build elixir      # Build static Elixir (includes Erlang)
sbeam verify            # Verify binaries are statically linked
sbeam test              # Test in Docker containers (Debian/Alpine/BusyBox)
sbeam clean             # Remove build artifacts
```

Direct Docker build (outside devenv):
```bash
docker build --target erlang -o ./static-erlang .
docker build --target elixir -o ./static-elixir .
docker build -t static-beam .
docker run --rm static-beam
```

## Architecture

- **Dockerfile**: Multi-stage Alpine Linux build. Compiles Erlang/OTP and Elixir from source inside native musl environment. Key configure flags: `--enable-static-nifs`, `--enable-static-drivers`, `--disable-dynamic-ssl-lib`, `LDFLAGS="-static"`. Export stages allow extracting binaries to host.

- **devenv.nix**: Development environment configuration using devenv. Defines the `sbeam` command which wraps Docker build commands. Uses `beam28Packages.{erlang,elixir}` for development tooling.

- **devenv.yaml**: Nix inputs configuration. Uses `nixpkgs-stable` (release-25.11) for reproducible builds.

- **nix/static-erlang.nix**: Legacy Nix-based static build attempt. Currently non-functional due to nixpkgs musl cross-compilation issues.

- **example/**: Example Elixir project demonstrating how to use static ERTS in mix releases via `include_erts` configuration.

## Static ERTS in Elixir Releases

The `STATIC_ERTS_PATH` environment variable is set automatically in devenv shell. Use it in mix.exs:
```elixir
include_erts: System.get_env("STATIC_ERTS_PATH")
```

## Versions

- Erlang/OTP: 27.2
- Elixir: 1.18.1
- Alpine: 3.21
- Development: beam28Packages
