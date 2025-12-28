# Static BEAM OTP Specification

## Purpose

Build fully static Erlang/OTP runtime for Elixir projects. The output binaries have **zero dynamic dependencies** and can run on any Linux distribution including minimal containers like `scratch`.

## Design Principles

### 1. Truly Static Binaries

- **No dynamic links**: `ldd beam.smp` must return "not a dynamic executable"
- **musl libc**: Preferred C library for static linking (not glibc)
- **Static OpenSSL**: Crypto and SSL statically linked
- **Static NIFs**: All native code compiled statically

### 2. Build Environment

- **Alpine Linux**: Native musl environment (no cross-compilation)
- **Docker-based**: Reproducible builds via multi-stage Dockerfile
- **GitHub Actions**: Automated builds for amd64 and arm64

### 3. Release Naming

```
Tag format: OTP-{otp-version}
Examples:   OTP-27.2, OTP-26.2.5, OTP-28.0
```

### 4. Output Artifacts

```
static-erlang-otp-{version}-linux-{arch}.tar.gz

Architectures:
- amd64 (x86_64)
- arm64 (aarch64)
```

### 5. Installation Path

Binaries are compiled with `--prefix=/opt/erlang`. Must be installed/mounted at this exact path.

## Technical Requirements

### Erlang Configure Flags

```bash
--enable-static-nifs       # Static NIFs
--enable-static-drivers    # Static drivers
--with-ssl                 # Include OpenSSL
--with-crypto              # Include crypto
LDFLAGS="-static"          # Static linking
```

### Excluded Components

```bash
--without-javac            # No Java
--without-wx               # No wxWidgets GUI
--without-odbc             # No ODBC
--without-observer         # No Observer GUI
--without-debugger         # No Debugger GUI
--without-et               # No Event Tracer
--without-megaco           # No Megaco
--without-jinterface       # No JInterface
```

### Required Static Libraries

- musl libc (via Alpine)
- OpenSSL (openssl-libs-static)
- ncurses (ncurses-static)
- zlib (zlib-static)

## Verification

A valid build must pass:

```bash
# Binary analysis
file beam.smp
# Expected: "statically linked"

# No dynamic dependencies
ldd beam.smp
# Expected: "not a dynamic executable"

# Runtime test
erl -noshell -eval 'io:format("OK"), halt().'
# Expected: "OK"

# Crypto test
erl -noshell -eval 'application:start(crypto), halt().'
# Expected: no error

# SSL test
erl -noshell -eval 'application:start(ssl), halt().'
# Expected: no error
```

## Usage in Elixir Projects

```elixir
# mix.exs
defp releases do
  [
    my_app: [
      include_erts: "/opt/erlang/lib/erlang"
    ]
  ]
end
```

## Non-Goals

- Elixir static build (use regular Elixir with static ERTS)
- Windows/macOS support
- GUI applications (wx, observer, debugger)
- Cross-compilation from glibc hosts
