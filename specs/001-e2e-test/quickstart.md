# Developer Quickstart: E2E Test Workflow

**Feature**: E2E Test Workflow with Demo App
**Branch**: `001-e2e-test`
**Date**: 2025-12-28

## Overview

This feature adds a manually-triggered GitHub Actions workflow to validate static Erlang releases using a demo Elixir application.

## Local Development

### Prerequisites

- Elixir 1.15+
- Static Erlang release at `/opt/erlang` (or Docker)

### Running the Demo App Locally

```bash
# Download static Erlang (example for amd64)
curl -L -o erlang.tar.gz \
  https://github.com/gsmlg-dev/static-BEAM-OTP/releases/download/OTP-27.2/static-erlang-otp-27.2-linux-amd64.tar.gz

# Extract to /opt/erlang
sudo mkdir -p /opt/erlang
sudo tar -xzf erlang.tar.gz -C /opt/erlang

# Build demo app release
cd demo
mix deps.get --only prod
MIX_ENV=prod mix release demo

# Run the release
_build/prod/rel/demo/bin/demo eval "Demo.health_check()"
```

### Running Tests

```bash
cd demo
mix test
```

## Workflow Usage

### Triggering the E2E Test

1. Go to GitHub Actions → "E2E Test" workflow
2. Click "Run workflow"
3. Enter release tag (e.g., `OTP-27.2`)
4. Click "Run workflow"

### Expected Output

The workflow runs tests on both amd64 and arm64, verifying:
- Release package downloads successfully
- Demo app builds with static ERTS
- Crypto functions work (hash generation)
- SSL/TLS connections work (HTTPS request)
- BEAM operations work (process spawn, message passing)

## File Structure

```
demo/
├── mix.exs           # Project config with include_erts
├── lib/demo.ex       # Main module with test functions
├── test/             # ExUnit tests
└── config/           # App configuration

.github/workflows/
└── e2e-test.yml      # Manual workflow
```

## Key Implementation Notes

1. **No external Elixir deps**: Demo uses only Erlang stdlib to avoid compile issues
2. **Health check via eval**: Uses `bin/demo eval` instead of HTTP endpoint
3. **Static ERTS path**: Must be `/opt/erlang/lib/erlang` (compiled-in prefix)
4. **Matrix builds**: amd64 and arm64 run in parallel

## Testing the Workflow

Before pushing, validate locally:

```bash
# Verify static Erlang works
/opt/erlang/bin/erl -noshell -eval 'io:format("OK~n"), halt().'

# Verify crypto
/opt/erlang/bin/erl -noshell -eval 'crypto:start(), io:format("Crypto OK~n"), halt().'

# Verify SSL
/opt/erlang/bin/erl -noshell -eval 'ssl:start(), io:format("SSL OK~n"), halt().'

# Build and test demo
cd demo && mix test
```
