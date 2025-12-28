# Research: E2E Test Workflow with Demo App

**Feature**: [spec.md](./spec.md)
**Date**: 2025-12-28
**Phase**: 0 - Research

## Research Summary

This feature has minimal research requirements as it uses well-established technologies:
- GitHub Actions `workflow_dispatch` for manual triggers
- Elixir Mix releases with `include_erts`
- Standard HTTP clients for SSL testing
- ExUnit for functional tests

## Key Findings

### 1. GitHub Actions Manual Triggers

```yaml
on:
  workflow_dispatch:
    inputs:
      release_tag:
        description: 'OTP release tag (e.g., OTP-27.2)'
        required: true
        type: string
```

- `workflow_dispatch` supports typed inputs (string, boolean, choice, environment)
- Inputs available via `${{ github.event.inputs.release_tag }}`
- Can download release assets via `gh release download`

### 2. Elixir Mix Release with Static ERTS

```elixir
# mix.exs
def project do
  [
    app: :demo,
    version: "0.1.0",
    elixir: "~> 1.15",
    releases: [
      demo: [
        include_erts: "/opt/erlang/lib/erlang"
      ]
    ]
  ]
end
```

- `include_erts` path must match the static Erlang installation
- Release built with `mix release demo`
- Output in `_build/prod/rel/demo/`

### 3. Crypto/SSL Testing in Elixir

**Crypto verification**:
```elixir
:crypto.hash(:sha256, "test") |> Base.encode16()
```

**SSL verification**:
```elixir
:ssl.start()
:httpc.request(:get, {~c"https://example.com", []}, [], [])
```

Or using Req/Finch for simpler HTTP:
```elixir
# Minimal - use built-in :httpc to avoid dependencies
:inets.start()
:ssl.start()
{:ok, {{_, 200, _}, _, _}} = :httpc.request(~c"https://httpbin.org/get")
```

### 4. BEAM Process Testing

```elixir
# Process spawning
pid = spawn(fn -> receive do msg -> msg end end)
send(pid, :hello)

# Message passing verification
parent = self()
spawn(fn -> send(parent, :response) end)
receive do :response -> :ok after 1000 -> :timeout end
```

### 5. GitHub-Hosted Runner Architectures

| Architecture | Runner Label | OS |
|-------------|--------------|-----|
| amd64 | `ubuntu-latest` | Ubuntu 22.04 |
| arm64 | `ubuntu-24.04-arm` | Ubuntu 24.04 ARM64 |

Both runners have:
- Docker pre-installed
- `gh` CLI available
- Network access to GitHub Releases

## Clarifications Resolved

All requirements from spec.md are clear. No `[NEEDS CLARIFICATION]` markers remain.

## Technical Decisions

1. **No external dependencies for demo app**: Use only Erlang stdlib (:crypto, :ssl, :httpc, :inets) to avoid Mix dependency issues
2. **Health check via eval**: Use `bin/demo eval "Demo.health_check()"` rather than HTTP endpoint to keep demo minimal
3. **Matrix strategy for architectures**: Run amd64 and arm64 in parallel for faster feedback

## References

- [GitHub Actions workflow_dispatch](https://docs.github.com/en/actions/using-workflows/events-that-trigger-workflows#workflow_dispatch)
- [Elixir Mix Releases](https://hexdocs.pm/mix/Mix.Tasks.Release.html)
- [Erlang :crypto module](https://www.erlang.org/doc/man/crypto.html)
