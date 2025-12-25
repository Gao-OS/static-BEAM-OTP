# Static BEAM

Build fully static Erlang/OTP and Elixir using musl libc with Nix.

The resulting binaries have **no dynamic dependencies** and run on any Linux distribution including Debian, Alpine, BusyBox, and even `scratch` containers.

## Features

- **Truly Static**: BEAM VM compiled with musl libc, no glibc dependencies
- **Portable**: Same binary works on Debian, Ubuntu, Alpine, BusyBox, scratch
- **Nix-based**: Reproducible builds with pinned dependencies
- **Complete**: Includes crypto, SSL, and all core OTP applications
- **Mix Releases**: Use static ERTS in your Elixir releases

## Quick Start

### Prerequisites

- [Nix](https://nixos.org/download.html) with flakes enabled
- Optional: Docker for testing

### Build Static BEAM

```bash
# Build static Erlang/OTP
nix build .#static-erlang

# Build static Elixir (includes Erlang)
nix build .#static-elixir

# Build both
nix build .#static-beam

# The result is in ./result
ls -la result/bin/
```

### Verify Binaries are Static

```bash
# Run verification script
./scripts/verify.sh

# Manual verification
file result/lib/erlang/erts-*/bin/beam.smp
# Output: ... statically linked ...

ldd result/lib/erlang/erts-*/bin/beam.smp
# Output: not a dynamic executable
```

### Test Portability

```bash
# Copy result for Docker
cp -rL result static-beam

# Build and run test container
docker build -t static-beam-test .
docker run --rm static-beam-test

# Test on specific distros
docker run --rm -v $(pwd)/static-beam:/opt/beam debian:bookworm-slim \
  /opt/beam/bin/erl -noshell -eval 'io:format("Hello from Debian!~n"), halt().'

docker run --rm -v $(pwd)/static-beam:/opt/beam alpine:3.19 \
  /opt/beam/bin/erl -noshell -eval 'io:format("Hello from Alpine!~n"), halt().'

docker run --rm -v $(pwd)/static-beam:/opt/beam busybox:musl \
  /opt/beam/bin/erl -noshell -eval 'io:format("Hello from BusyBox!~n"), halt().'
```

## Development Environment

### Using devenv

```bash
# Enter development shell
devenv shell

# Available commands:
build-static-erlang   # Build static Erlang/OTP
build-static-elixir   # Build static Elixir
build-static-beam     # Build both
verify-static         # Verify binaries are static
test-docker           # Run Docker tests
```

### Using Nix Flake

```bash
# Enter development shell
nix develop

# Build packages
nix build .#static-erlang
nix build .#static-elixir
nix build .#static-beam
```

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
        # Point to static ERTS from Nix build
        include_erts: System.get_env("STATIC_ERTS_PATH") ||
                      "/path/to/static-beam/lib/erlang",
        strip_beams: true,
        steps: [:assemble, :tar]
      ]
    ]
  end
end
```

### Build Release

```bash
# Set the static ERTS path
export STATIC_ERTS_PATH=$(readlink -f result/lib/erlang)

# Build production release
MIX_ENV=prod mix release

# The release in _build/prod/rel/my_app/ uses static ERTS
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
├── flake.nix              # Nix flake with packages and shells
├── devenv.nix             # devenv development environment
├── nix/
│   ├── static-erlang.nix  # Static Erlang/OTP derivation
│   └── static-elixir.nix  # Static Elixir derivation
├── scripts/
│   ├── build.sh           # Build helper script
│   └── verify.sh          # Verification script
├── example/               # Example Elixir project
│   ├── mix.exs
│   ├── lib/
│   └── build-release.sh
├── Dockerfile             # Multi-distro test Dockerfile
└── README.md
```

## Static Build Configuration

### Erlang Configure Flags

The following flags are used to build static Erlang:

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

## Troubleshooting

### Build Fails with SSL Errors

Ensure OpenSSL is properly configured:

```bash
# Check if static OpenSSL is available
nix build nixpkgs#pkgsCross.musl64.pkgsStatic.openssl
```

### Binary Not Static

Check the verification output:

```bash
./scripts/verify.sh result

# If ldd shows dynamic libraries, rebuild with:
nix build .#static-erlang --rebuild
```

### Release Doesn't Start

Verify the ERTS path is correct:

```bash
ls $STATIC_ERTS_PATH/bin/erl
ls $STATIC_ERTS_PATH/erts-*/bin/beam.smp
```

## Versions

- **Erlang/OTP**: 26.2.5
- **Elixir**: 1.16.3
- **musl libc**: Latest from nixpkgs

## License

This project is provided under the MIT license. Erlang/OTP is licensed under Apache 2.0.

## Credits

Built with [Nix](https://nixos.org/) and [musl libc](https://musl.libc.org/).
