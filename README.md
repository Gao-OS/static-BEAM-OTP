# Static BEAM

Build fully static Erlang/OTP and Elixir using musl libc with Nix.

**STATUS: Work in Progress** - The nixpkgs musl/static Erlang builds currently fail due to missing bootstrap Erlang configuration in cross-compilation. See [Known Issues](#known-issues) below.

## Goal

The goal is to produce binaries that have **no dynamic dependencies** and run on any Linux distribution including Debian, Alpine, BusyBox, and even `scratch` containers.

## Planned Features

- **Truly Static**: BEAM VM compiled with musl libc, no glibc dependencies
- **Portable**: Same binary works on Debian, Ubuntu, Alpine, BusyBox, scratch
- **Nix-based**: Reproducible builds with pinned dependencies
- **Complete**: Includes crypto, SSL, and all core OTP applications
- **Mix Releases**: Use static ERTS in your Elixir releases

## Quick Start

### Prerequisites

- [Nix](https://nixos.org/download.html)
- [devenv](https://devenv.sh/)

### Enter Development Environment

```bash
devenv shell
```

### Build Static BEAM

```bash
# Build static Erlang/OTP
sbeam build erlang

# Or build static Elixir (includes Erlang)
sbeam build elixir

# The result is in ./result
ls -la result/bin/
```

### Verify Binaries are Static

```bash
sbeam verify

# Output should show "statically linked"
```

### Test Portability

```bash
# Test in Docker containers
sbeam test

# Or manually test on specific distros
docker run --rm -v $(pwd)/static-beam:/opt/beam debian:bookworm-slim \
  /opt/beam/bin/erl -noshell -eval 'io:format("Hello from Debian!~n"), halt().'

docker run --rm -v $(pwd)/static-beam:/opt/beam alpine:3.19 \
  /opt/beam/bin/erl -noshell -eval 'io:format("Hello from Alpine!~n"), halt().'

docker run --rm -v $(pwd)/static-beam:/opt/beam busybox:musl \
  /opt/beam/bin/erl -noshell -eval 'io:format("Hello from BusyBox!~n"), halt().'
```

## Commands

| Command | Description |
|---------|-------------|
| `sbeam build [erlang\|elixir\|all]` | Build static BEAM |
| `sbeam verify [path]` | Verify binaries are static |
| `sbeam test` | Test in Docker containers |
| `sbeam clean` | Remove build artifacts |
| `sbeam help` | Show help |

## Using Static ERTS in Elixir Releases

### Configure mix.exs

```elixir
defmodule MyApp.MixProject do
  use Mix.Project

  def project do
    [
      app: :my_app,
      version: "0.1.0",
      elixir: "~> 1.15",
      releases: releases()
    ]
  end

  defp releases do
    [
      my_app: [
        # Point to static ERTS from build
        include_erts: System.get_env("STATIC_ERTS_PATH") ||
                      "/path/to/result/lib/erlang",
        strip_beams: true,
        steps: [:assemble, :tar]
      ]
    ]
  end
end
```

### Build Release

```bash
# STATIC_ERTS_PATH is set automatically in devenv shell
MIX_ENV=prod mix release

# The release uses static ERTS
```

### Deploy to Minimal Container

```dockerfile
FROM scratch

COPY _build/prod/rel/my_app /app

ENTRYPOINT ["/app/bin/my_app"]
CMD ["start"]
```

## Project Structure

```
static-beam/
├── devenv.nix             # Development environment and sbeam command
├── nix/
│   ├── static-erlang.nix  # Static Erlang/OTP derivation
│   └── static-elixir.nix  # Static Elixir derivation
├── example/               # Example Elixir project
│   ├── mix.exs
│   └── lib/
├── Dockerfile             # Multi-distro test
└── README.md
```

## Static Build Configuration

### Erlang Configure Flags

```bash
--enable-static-nifs       # Build NIFs as static
--enable-static-drivers    # Build drivers as static
--disable-dynamic-ssl-lib  # Static SSL
--disable-shared           # No shared libraries
--without-javac            # Skip Java
--without-wx               # Skip wxWidgets
--without-odbc             # Skip ODBC
--without-megaco           # Skip Megaco
--without-observer         # Skip Observer
--without-debugger         # Skip Debugger
--without-et               # Skip Event Tracer
--without-jinterface       # Skip JInterface
```

### Static Dependencies

All dependencies are statically linked:

- **OpenSSL**: Crypto and SSL support
- **ncurses**: Terminal support
- **zlib**: Compression support

## Versions

- **Erlang/OTP**: 28.2
- **Elixir**: 1.18.4
- **musl libc**: Latest from nixpkgs

## Known Issues

The static build currently fails due to issues in nixpkgs' musl/static Erlang cross-compilation:

1. **Missing Bootstrap Erlang**: All nixpkgs musl Erlang variants (`pkgsCross.musl64.erlang`, `pkgsStatic.erlang`, `beamMinimalPackages`, etc.) fail with:
   ```
   No usable Erlang/OTP system for the build machine found!
   Cannot cross compile without such a system.
   ```
   This is because the derivations don't include a bootstrap Erlang in their `nativeBuildInputs`.

2. **wxWidgets Dependencies**: The full Erlang package tries to build wxWidgets, which pulls in complex dependencies (webkit, libglvnd) that don't build on musl.

3. **Static Linking Complexity**: When adding `--enable-static-nifs` and `--enable-static-drivers`, cross-compilation of NIF C code fails to find `erl_nif.h`.

### Potential Workarounds

- Build inside an Alpine Linux container (native musl, no cross-compilation)
- Use Docker multi-stage builds
- Wait for nixpkgs to fix the musl Erlang cross-compilation setup
- File an issue upstream at https://github.com/NixOS/nixpkgs/issues

## License

MIT. Erlang/OTP is licensed under Apache 2.0.
