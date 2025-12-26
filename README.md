# Static BEAM

Build fully static Erlang/OTP and Elixir using Alpine Linux and musl libc.

## Goal

Produce binaries with **no dynamic dependencies** that run on any Linux distribution including Debian, Alpine, BusyBox, and even `scratch` containers.

## Features

- **Truly Static**: BEAM VM compiled with musl libc, no glibc dependencies
- **Portable**: Same binary works on Debian, Ubuntu, Alpine, BusyBox, scratch
- **Docker-based**: Builds inside Alpine container (native musl, no cross-compilation)
- **Complete**: Includes crypto, SSL, and all core OTP applications
- **Mix Releases**: Use static ERTS in your Elixir releases

## Quick Start

### Prerequisites

- [Docker](https://docs.docker.com/get-docker/)
- [devenv](https://devenv.sh/) (optional, for development environment)

### Build with Docker directly

```bash
# Build static Erlang/OTP
docker build --target erlang -o ./static-erlang .

# Build static Elixir
docker build --target elixir -o ./static-elixir .

# Build and test
docker build -t static-beam .
docker run --rm static-beam
```

### Build with devenv

```bash
# Enter development environment
devenv shell

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
docker run --rm -v $(pwd)/result:/opt/beam debian:bookworm-slim \
  /opt/beam/bin/erl -noshell -eval 'io:format("Hello from Debian!~n"), halt().'

docker run --rm -v $(pwd)/result:/opt/beam alpine:3.21 \
  /opt/beam/bin/erl -noshell -eval 'io:format("Hello from Alpine!~n"), halt().'

docker run --rm -v $(pwd)/result:/opt/beam busybox:musl \
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

## How It Works

The build uses a multi-stage Docker approach:

1. **Alpine Builder**: Compiles Erlang/OTP from source inside Alpine Linux (native musl)
2. **Static Linking**: Uses `LDFLAGS="-static"` and static library variants
3. **Export Stage**: Extracts binaries to host via `docker build -o`

This avoids cross-compilation complexity by building in a native musl environment.

## Project Structure

```
static-beam/
├── Dockerfile             # Multi-stage Alpine build
├── devenv.nix             # Development environment and sbeam command
├── nix/
│   ├── static-erlang.nix  # (Legacy) Nix-based static build attempt
│   └── static-elixir.nix  # (Legacy) Nix-based static Elixir
├── example/               # Example Elixir project
│   ├── mix.exs
│   └── lib/
└── README.md
```

## Static Build Configuration

### Erlang Configure Flags

```bash
--enable-static-nifs       # Build NIFs as static
--enable-static-drivers    # Build drivers as static
--disable-dynamic-ssl-lib  # Static SSL
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

- **Erlang/OTP**: 27.2
- **Elixir**: 1.18.1
- **Alpine**: 3.21

## License

MIT. Erlang/OTP is licensed under Apache 2.0.
