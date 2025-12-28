# Feature Specification: E2E Test Workflow with Demo App

**Feature Branch**: `001-e2e-test`
**Created**: 2025-12-28
**Status**: Draft
**Input**: Add a e2e test workflow, it is manual triggered, it's input is the release tag. There should have a demo app, the workflow fetch the release package and use in demo app, release the app, then test the app ensure it works.

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Verify Release with Demo App (Priority: P1)

A maintainer wants to verify that a specific OTP release works correctly with a real Elixir application before recommending it to users.

**Why this priority**: This is the core purpose of the e2e test - ensuring releases are production-ready by testing with an actual Elixir application.

**Independent Test**: Can be fully tested by triggering the workflow with a release tag and observing that the demo app builds, starts, and responds correctly.

**Acceptance Scenarios**:

1. **Given** a valid release tag (e.g., `OTP-27.2`), **When** the maintainer triggers the e2e workflow, **Then** the workflow downloads the release package for the correct architecture
2. **Given** the release package is downloaded, **When** the demo app is built with static ERTS, **Then** the build completes successfully without errors
3. **Given** the demo app is built, **When** the app is started, **Then** it responds to health checks within 30 seconds
4. **Given** the demo app is running, **When** functional tests are executed, **Then** all tests pass confirming crypto, SSL, and basic Elixir functionality work

---

### User Story 2 - Multi-Architecture Validation (Priority: P2)

A maintainer wants to ensure the release works on both amd64 and arm64 architectures.

**Why this priority**: Multi-arch support is essential for users deploying to different platforms (Intel servers, AWS Graviton, Apple Silicon).

**Independent Test**: Can be tested by running the workflow and verifying both architecture builds succeed and pass tests.

**Acceptance Scenarios**:

1. **Given** a release tag with both amd64 and arm64 packages, **When** the workflow runs, **Then** both architectures are tested independently
2. **Given** both architecture tests complete, **When** reviewing results, **Then** maintainer can see pass/fail status for each architecture

---

### User Story 3 - Failure Reporting (Priority: P3)

A maintainer wants clear feedback when a release has issues, so they can debug and fix problems.

**Why this priority**: Debugging failed releases requires clear error messages and logs.

**Independent Test**: Can be tested by intentionally using an invalid tag or breaking the demo app to verify error reporting.

**Acceptance Scenarios**:

1. **Given** an invalid release tag, **When** the workflow runs, **Then** it fails with a clear error message indicating the release was not found
2. **Given** the demo app fails to start, **When** the workflow runs, **Then** relevant logs are captured and displayed
3. **Given** any test failure, **When** reviewing the workflow, **Then** the specific failing test and error are clearly identified

---

### Edge Cases

- What happens when the release tag doesn't exist? Workflow fails with clear "Release not found" error
- What happens when the release only has one architecture? Test only available architectures, skip missing ones with warning
- What happens when the demo app has a dependency issue? Fail at build stage with dependency error in logs
- What happens when network issues occur during package download? Fail with network error, no retry (GitHub Actions handles retries)

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: Workflow MUST be manually triggerable via GitHub Actions `workflow_dispatch`
- **FR-002**: Workflow MUST accept a release tag as required input (e.g., `OTP-27.2`)
- **FR-003**: Workflow MUST download the static Erlang package from the specified release tag
- **FR-004**: Workflow MUST test both amd64 and arm64 architectures
- **FR-005**: Repository MUST include a demo Elixir application
- **FR-006**: Demo app MUST be configured to use downloaded static ERTS via `include_erts`
- **FR-007**: Demo app MUST be built as a Mix release
- **FR-008**: Workflow MUST verify the demo app starts successfully
- **FR-009**: Workflow MUST run functional tests against the demo app
- **FR-010**: Functional tests MUST verify crypto module works (e.g., hash generation)
- **FR-011**: Functional tests MUST verify SSL/TLS works (e.g., HTTPS request)
- **FR-012**: Functional tests MUST verify basic BEAM operations (process spawning, message passing)
- **FR-013**: Workflow MUST report clear pass/fail status per architecture
- **FR-014**: Workflow MUST display relevant logs on any failure

### Key Entities

- **Release Tag**: The OTP version identifier (e.g., `OTP-27.2`) input by the user
- **Demo App**: A minimal Elixir application that exercises crypto, SSL, and BEAM features
- **Static ERTS Package**: The pre-built tarball downloaded from GitHub Releases
- **Functional Tests**: Scripts or test commands that verify the demo app works correctly

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: Maintainers can trigger e2e test within 1 minute via GitHub Actions UI
- **SC-002**: Complete e2e test (both architectures) completes in under 10 minutes
- **SC-003**: 100% of failures produce error messages that identify the failing component
- **SC-004**: Demo app starts and passes health check on both architectures when release is valid
- **SC-005**: All BEAM core features (crypto, SSL, process spawning) are validated

## Assumptions

- Demo app will be a minimal Elixir application (not Phoenix, to keep it simple)
- Health checks will use simple Erlang evaluation or HTTP endpoint
- Workflow runs on GitHub-hosted runners (ubuntu-latest for amd64, ubuntu-24.04-arm for arm64)
- Release packages follow naming: `static-erlang-otp-{version}-linux-{arch}.tar.gz`
- Demo app lives in `demo/` directory within the repository
