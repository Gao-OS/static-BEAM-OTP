# Static BEAM

Build fully static Erlang/OTP using Alpine Linux and musl libc.

## Features

- **Truly Static**: BEAM VM compiled with musl libc, no dynamic dependencies
- **Portable**: Same binary runs on Debian, Ubuntu, Alpine, BusyBox, scratch containers
- **Docker-based**: Builds inside Alpine container (native musl, no cross-compilation)
- **Complete**: Includes crypto, SSL, and core OTP applications

## Quick Start

### Build

```bash
# Build static Erlang/OTP (outputs to ./static-erlang/)
docker build --target erlang -o ./static-erlang .

# Build and run tests
docker build -t static-beam . && docker run --rm static-beam
```

### Use

**Important**: Mount at `/opt/erlang` (paths are compiled in).

```bash
# Run on Debian
docker run --rm -v ./static-erlang:/opt/erlang debian:bookworm-slim \
  /opt/erlang/bin/erl -noshell -eval 'io:format("Hello from Debian!~n"), halt().'

# Run on Alpine
docker run --rm -v ./static-erlang:/opt/erlang alpine:3.21 \
  /opt/erlang/bin/erl -noshell -eval 'io:format("Hello from Alpine!~n"), halt().'

# Run on BusyBox
docker run --rm -v ./static-erlang:/opt/erlang busybox:musl \
  /opt/erlang/bin/erl -noshell -eval 'io:format("Hello from BusyBox!~n"), halt().'

# Run on scratch (minimal container)
docker run --rm -v ./static-erlang:/opt/erlang scratch \
  /opt/erlang/bin/erl -noshell -eval 'io:format("Hello from scratch!~n"), halt().'
```

### Verify Static Linking

```bash
# Check binary type
file static-erlang/lib/erlang/erts-*/bin/beam.smp
# Output: ELF 64-bit LSB executable, x86-64, statically linked

# Verify no dynamic dependencies
ldd static-erlang/lib/erlang/erts-*/bin/beam.smp
# Output: not a dynamic executable
```

## Using with devenv

```bash
# Enter development environment
devenv shell

# Build
sbeam build erlang

# Verify
sbeam verify

# Test in containers
sbeam test
```

## Using Static ERTS in Elixir Releases

```elixir
# mix.exs
defmodule MyApp.MixProject do
  use Mix.Project

  def project do
    [
      app: :my_app,
      version: "0.1.0",
      releases: [
        my_app: [
          include_erts: "/opt/erlang/lib/erlang",
          steps: [:assemble, :tar]
        ]
      ]
    ]
  end
end
```

### Deploy to Minimal Container

```dockerfile
FROM scratch
COPY _build/prod/rel/my_app /app
COPY --from=builder /opt/erlang /opt/erlang
ENTRYPOINT ["/app/bin/my_app"]
CMD ["start"]
```

## How It Works

```
┌─────────────────────────────────────────────────────────────┐
│  Alpine Linux (native musl)                                 │
│  ┌───────────────────────────────────────────────────────┐  │
│  │  Build Erlang/OTP from source                         │  │
│  │  LDFLAGS="-static"                                    │  │
│  │  --enable-static-nifs --enable-static-drivers         │  │
│  └───────────────────────────────────────────────────────┘  │
│                           ↓                                 │
│  ┌───────────────────────────────────────────────────────┐  │
│  │  Static binaries in /opt/erlang                       │  │
│  │  - beam.smp (statically linked)                       │  │
│  │  - erlexec, erl, erlc, etc.                          │  │
│  └───────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                           ↓
         docker build --target erlang -o ./static-erlang .
                           ↓
┌─────────────────────────────────────────────────────────────┐
│  ./static-erlang/                                           │
│  ├── bin/erl, erlc, ...                                    │
│  └── lib/erlang/erts-15.2/bin/beam.smp (static!)           │
└─────────────────────────────────────────────────────────────┘
```

## Versions

| Component | Version |
|-----------|---------|
| Erlang/OTP | 27.2 |
| Alpine | 3.21 |
| OpenSSL | 3.3.x (static) |

## Project Structure

```
static-beam/
├── Dockerfile          # Multi-stage Alpine build
├── devenv.nix          # Development environment + sbeam command
├── .github/workflows/  # CI/CD
└── README.md
```

## Dockerfile Targets

| Target | Description |
|--------|-------------|
| `erlang` | Export static Erlang to host |
| `test` | Run verification tests |
| (default) | Build and test |

## Known Limitations

- **Mount path**: Must mount at `/opt/erlang` (paths are compiled in)
- **Elixir**: Static Elixir build has SSL linking issues (WIP)

## License

MIT. Erlang/OTP is licensed under Apache 2.0.
