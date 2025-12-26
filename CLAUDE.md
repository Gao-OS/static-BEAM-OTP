# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Static BEAM builds fully static Erlang/OTP and Elixir binaries using musl libc. The resulting binaries have zero dynamic dependencies and run on any Linux distribution (Debian, Alpine, BusyBox, scratch containers).

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

Direct nix-build (outside devenv):
```bash
nix-build nix/static-erlang.nix -o result
nix-build nix/static-elixir.nix -o result
```

## Architecture

- **devenv.nix**: Development environment configuration using devenv. Defines the `sbeam` command, packages from `pkgs-stable`, and enables `beam28Packages.{erlang,elixir}` for development.

- **devenv.yaml**: Nix inputs configuration. Uses `nixpkgs-stable` (release-25.11) for reproducible builds.

- **nix/static-erlang.nix**: Standalone Nix derivation that builds Erlang/OTP 26.2.5 with musl libc. Uses `pkgsCross.musl64.pkgsStatic` for cross-compilation. Key configure flags: `--enable-static-nifs`, `--enable-static-drivers`, `--disable-dynamic-ssl-lib`. Static dependencies: OpenSSL, ncurses, zlib.

- **nix/static-elixir.nix**: Builds Elixir 1.16.3 using the static Erlang from `static-erlang.nix`. Wraps binaries to use static ERTS.

- **example/**: Example Elixir project demonstrating how to use static ERTS in mix releases via `include_erts` configuration.

- **Dockerfile**: Multi-stage build testing portability across Debian, Alpine, and BusyBox.

## Static ERTS in Elixir Releases

The `STATIC_ERTS_PATH` environment variable is set automatically in devenv shell. Use it in mix.exs:
```elixir
include_erts: System.get_env("STATIC_ERTS_PATH")
```

## Versions

- Erlang/OTP: 28.2
- Elixir: 1.18.4
- Development: beam28Packages
