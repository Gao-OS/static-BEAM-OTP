<!--
SYNC IMPACT REPORT
==================
Version change: 0.0.0 → 1.0.0 (initial constitution)

Modified principles: N/A (initial)

Added sections:
  - Core Principles (5 principles)
  - Build Constraints
  - Release Process
  - Governance

Removed sections: N/A (initial)

Templates requiring updates:
  - .specify/templates/plan-template.md: ✅ No changes needed (Constitution Check section is generic)
  - .specify/templates/spec-template.md: ✅ No changes needed (generic format)
  - .specify/templates/tasks-template.md: ✅ No changes needed (generic format)

Follow-up TODOs: None
-->

# Static BEAM Constitution

## Core Principles

### I. Zero Dynamic Dependencies

All output binaries MUST have zero dynamic library dependencies. Verification is mandatory:

- `ldd` MUST return "not a dynamic executable" for beam.smp, erlexec, and all ERTS binaries
- `file` MUST report "statically linked" for all executables
- CI MUST fail if any binary has dynamic dependencies

**Rationale**: The entire value proposition is portability. A single dynamic dependency breaks deployment to scratch containers and non-glibc systems.

### II. Cross-Distribution Portability

Static binaries MUST run identically on any Linux distribution:

- Debian/Ubuntu (glibc)
- Alpine (musl)
- BusyBox (musl)
- scratch containers (no libc)

CI MUST test all target distributions on every build. Test failures block releases.

**Rationale**: Users embed these binaries in minimal containers and heterogeneous environments. Untested distributions are unsupported distributions.

### III. Multi-Architecture Parity

Both amd64 and arm64 architectures MUST be first-class citizens:

- Builds MUST succeed for both architectures
- Tests MUST pass for both architectures
- Releases MUST include both architecture tarballs
- No architecture-specific workarounds that break the other

**Rationale**: arm64 adoption (AWS Graviton, Apple Silicon) requires equal support. Architecture-specific bugs are release blockers.

### IV. Reproducible Builds

Build outputs MUST be deterministic given the same inputs:

- Dockerfile pins Alpine version explicitly
- OTP and Elixir versions are pinned as ARG values
- OpenSSL version comes from Alpine's package manager (pinned by Alpine version)
- Build flags and patches are documented inline

**Rationale**: Users must be able to rebuild identical binaries for security audits and compliance. "Works on my machine" is unacceptable.

### V. Crypto/SSL Functional

Static builds MUST include working crypto and SSL:

- `crypto:start/0` MUST succeed
- `ssl:start/0` MUST succeed
- OpenSSL MUST be statically linked (not dynamically loaded)
- TLS 1.2/1.3 MUST be operational

CI MUST verify crypto functionality on all target distributions.

**Rationale**: Most production Erlang/Elixir applications require crypto/SSL. A static build without working crypto is unusable.

## Build Constraints

All changes to the build process MUST satisfy:

| Constraint | Requirement |
|------------|-------------|
| Base image | Alpine Linux (native musl, no cross-compilation) |
| Mount path | `/opt/erlang` (paths are compiled in, non-negotiable) |
| Build flags | `--enable-static-nifs --enable-static-drivers` required |
| Link flags | `-static` for all ERTS binaries |
| Tag format | `OTP-{version}` (e.g., `OTP-28.2`) |
| Artifacts | `static-erlang-otp-{version}-linux-{arch}.tar.gz` |

Deviations require explicit justification and amendment to this constitution.

## Release Process

1. **Version bump**: Update `ARG OTP_VERSION` and `ARG ELIXIR_VERSION` in Dockerfile
2. **Local verification**: `docker build -t static-beam . && docker run --rm static-beam`
3. **Push to main**: CI builds and tests automatically
4. **Tag release**: `git tag OTP-{version} && git push origin OTP-{version}`
5. **Automated release**: GitHub Actions creates release with both architecture tarballs
6. **E2E validation**: Run E2E test workflow against the release

Releases MUST NOT be created manually. The CI pipeline is the source of truth.

## Governance

This constitution supersedes all other documentation when conflicts arise.

**Amendment process**:
1. Propose change via pull request modifying this file
2. Document rationale for the change
3. Update version according to semantic versioning:
   - MAJOR: Principle removal or incompatible redefinition
   - MINOR: New principle or significant expansion
   - PATCH: Clarifications and wording improvements
4. Update dependent templates if principles change

**Compliance verification**:
- All PRs MUST pass CI (enforces Principles I-V automatically)
- Code review MUST verify adherence to Build Constraints
- Release process violations block the release

**Version**: 1.0.0 | **Ratified**: 2025-01-28 | **Last Amended**: 2025-01-28
