# Implementation Plan: E2E Test Workflow with Demo App

**Branch**: `001-e2e-test` | **Date**: 2025-12-28 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/001-e2e-test/spec.md`

## Summary

Create a manually-triggered GitHub Actions workflow that validates static Erlang releases using a demo Elixir application. The workflow accepts a release tag (e.g., `OTP-27.2`), downloads the corresponding static ERTS packages for both amd64 and arm64, builds a demo app with `include_erts`, and runs functional tests to verify crypto, SSL, and BEAM operations work correctly.

## Technical Context

**Language/Version**: Elixir 1.15+ (for demo app), YAML (for workflow)
**Primary Dependencies**: Mix (Elixir build tool), GitHub Actions
**Storage**: N/A (stateless workflow)
**Testing**: Mix test, shell scripts for runtime verification
**Target Platform**: GitHub Actions runners (ubuntu-latest for amd64, ubuntu-24.04-arm for arm64)
**Project Type**: Single project with workflow + demo app
**Performance Goals**: Complete e2e test in under 10 minutes for both architectures
**Constraints**: Must work with GitHub-hosted runners, no external services
**Scale/Scope**: Single workflow, one demo app, tests run per-architecture

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

Based on SPECKIT.md (project constitution):

| Principle | Compliance | Notes |
|-----------|------------|-------|
| Truly Static Binaries | ✅ Pass | E2E test validates static linking via `ldd` |
| musl libc | ✅ Pass | Tests verify binaries from Alpine builds |
| Release Naming (OTP-{version}) | ✅ Pass | Workflow input follows `OTP-{version}` format |
| Multi-arch (amd64 + arm64) | ✅ Pass | Workflow tests both architectures |
| Installation Path (/opt/erlang) | ✅ Pass | Demo app uses correct include_erts path |
| Verification Tests | ✅ Pass | Tests crypto, SSL, runtime as specified |

**Gate Status**: ✅ PASSED - No violations

## Project Structure

### Documentation (this feature)

```text
specs/001-e2e-test/
├── plan.md              # This file
├── spec.md              # Feature specification
├── research.md          # Phase 0 output
├── data-model.md        # Phase 1 output (N/A - no data model)
├── quickstart.md        # Phase 1 output
├── contracts/           # Phase 1 output (N/A - no API)
└── tasks.md             # Phase 2 output
```

### Source Code (repository root)

```text
demo/
├── mix.exs              # Demo Elixir app configuration with include_erts
├── lib/
│   └── demo.ex          # Main module with crypto/SSL/BEAM tests
├── test/
│   └── demo_test.exs    # ExUnit tests
└── config/
    └── config.exs       # App configuration

.github/workflows/
└── e2e-test.yml         # Manual workflow for e2e testing
```

**Structure Decision**: Simple single-project structure with demo app in `demo/` directory and workflow in `.github/workflows/`. No complex patterns needed - this is a straightforward CI/CD validation workflow.

## Complexity Tracking

> No constitution violations to justify.

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| N/A | N/A | N/A |
