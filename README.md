# Static BEAM

Build fully static Erlang/OTP using Alpine Linux and musl libc.

## Features

- **Truly Static**: BEAM VM compiled with musl libc, no dynamic dependencies
- **Portable**: Same binary runs on Debian, Ubuntu, Alpine, BusyBox, scratch containers
- **Docker-based**: Builds inside Alpine container (native musl, no cross-compilation)
- **Complete**: Includes crypto, SSL, and core OTP applications

## Download

Download pre-built static Erlang from [GitHub Releases](https://github.com/Gao-OS/static-BEAM-OTP/releases):

```bash
# Download latest release
curl -LO https://github.com/Gao-OS/static-BEAM-OTP/releases/latest/download/static-erlang-otp-27.2-linux-x86_64.tar.gz

# Extract
tar -xzf static-erlang-otp-27.2-linux-x86_64.tar.gz

# Move to /opt/erlang (required path)
sudo mv static-erlang /opt/erlang
```

Or download via script:

```bash
#!/bin/bash
VERSION="v1.0.0"  # Check releases for latest
OTP="27.2"

curl -L "https://github.com/Gao-OS/static-BEAM-OTP/releases/download/${VERSION}/static-erlang-otp-${OTP}-linux-x86_64.tar.gz" | \
  tar -xz -C /opt && mv /opt/static-erlang /opt/erlang
```

## Quick Start

### Build from Source

```bash
# Build static Erlang/OTP (outputs to ./static-erlang/)
docker build --target erlang -o ./static-erlang .

# Build and run tests
docker build -t static-beam . && docker run --rm static-beam
```

### Use

**Important**: Must be at `/opt/erlang` (paths are compiled in).

```bash
# Run on Debian
docker run --rm -v /opt/erlang:/opt/erlang debian:bookworm-slim \
  /opt/erlang/bin/erl -noshell -eval 'io:format("Hello from Debian!~n"), halt().'

# Run on Alpine
docker run --rm -v /opt/erlang:/opt/erlang alpine:3.21 \
  /opt/erlang/bin/erl -noshell -eval 'io:format("Hello from Alpine!~n"), halt().'

# Run on scratch (minimal container)
docker run --rm -v /opt/erlang:/opt/erlang scratch \
  /opt/erlang/bin/erl -noshell -eval 'io:format("Hello from scratch!~n"), halt().'
```

### Verify Static Linking

```bash
file /opt/erlang/lib/erlang/erts-*/bin/beam.smp
# Output: ELF 64-bit LSB executable, x86-64, statically linked

ldd /opt/erlang/lib/erlang/erts-*/bin/beam.smp
# Output: not a dynamic executable
```

## Using with Elixir Mix Releases

### 1. Download Static ERTS

```bash
# In your project directory
mkdir -p priv/static-erts

curl -L "https://github.com/Gao-OS/static-BEAM-OTP/releases/latest/download/static-erlang-otp-27.2-linux-x86_64.tar.gz" | \
  tar -xz -C priv/static-erts --strip-components=1
```

### 2. Configure mix.exs

```elixir
defmodule MyApp.MixProject do
  use Mix.Project

  def project do
    [
      app: :my_app,
      version: "0.1.0",
      elixir: "~> 1.15",
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      releases: releases()
    ]
  end

  defp releases do
    [
      my_app: [
        # Use static ERTS for production builds
        include_erts: static_erts_path(),
        strip_beams: true,
        steps: [:assemble, :tar]
      ]
    ]
  end

  defp static_erts_path do
    # Use static ERTS if available, otherwise use system ERTS
    static_path = Path.expand("priv/static-erts/lib/erlang", __DIR__)

    if File.exists?(static_path) do
      static_path
    else
      true  # Use system ERTS
    end
  end

  defp deps do
    []
  end
end
```

### 3. Build Release

```bash
MIX_ENV=prod mix release
```

### 4. Deploy to Minimal Container

```dockerfile
# Dockerfile for your Elixir app
FROM elixir:1.18-alpine AS builder

WORKDIR /app
COPY . .

# Download static ERTS
RUN mkdir -p priv/static-erts && \
    wget -qO- "https://github.com/Gao-OS/static-BEAM-OTP/releases/latest/download/static-erlang-otp-27.2-linux-x86_64.tar.gz" | \
    tar -xz -C priv/static-erts --strip-components=1

# Build release
RUN mix deps.get --only prod && \
    MIX_ENV=prod mix release

# Minimal runtime image
FROM scratch

# Copy the release (includes static ERTS)
COPY --from=builder /app/_build/prod/rel/my_app /app

# Copy SSL certificates for HTTPS
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

ENTRYPOINT ["/app/bin/my_app"]
CMD ["start"]
```

### 5. Build and Run

```bash
docker build -t my_app .
docker run --rm my_app
```

## Alternative: Environment Variable

You can also use an environment variable:

```elixir
# mix.exs
defp releases do
  [
    my_app: [
      include_erts: System.get_env("STATIC_ERTS_PATH") || true,
      strip_beams: true
    ]
  ]
end
```

```bash
# Build with static ERTS
STATIC_ERTS_PATH=/opt/erlang/lib/erlang MIX_ENV=prod mix release
```

## Using with devenv

```bash
devenv shell        # Enter development environment
sbeam build erlang  # Build static Erlang
sbeam verify        # Verify binaries are static
sbeam test          # Test in Docker containers
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
│  ./static-erlang/ → /opt/erlang/                            │
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

## Creating a Release

To create a new release:

```bash
git tag v1.0.0
git push origin v1.0.0
```

GitHub Actions will automatically build and publish the release.

## Known Limitations

- **Mount path**: Must be at `/opt/erlang` (paths are compiled in)
- **Architecture**: Currently only `linux-x86_64`
- **Elixir**: Static Elixir build has SSL linking issues (use regular Elixir with static ERTS)

## License

MIT. Erlang/OTP is licensed under Apache 2.0.
