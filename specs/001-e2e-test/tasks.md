# Tasks: E2E Test Workflow with Demo App

**Input**: Design documents from `/specs/001-e2e-test/`
**Prerequisites**: plan.md, spec.md, research.md, quickstart.md

**Tests**: Tests are implicitly included as functional verification in the demo app itself.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US2, US3)
- Include exact file paths in descriptions

## Path Conventions

Based on plan.md structure:
- Demo app: `demo/`
- Workflow: `.github/workflows/`

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and demo app structure

- [x] T001 Create demo app directory structure per plan.md at demo/
- [x] T002 Initialize Elixir project with mix.exs at demo/mix.exs
- [x] T003 [P] Create demo app config at demo/config/config.exs

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core demo app implementation that enables all user stories

**CRITICAL**: The demo app must be functional before workflow can test it

- [x] T004 [P] Implement crypto verification function in demo/lib/demo.ex
- [x] T005 [P] Implement SSL/TLS verification function in demo/lib/demo.ex
- [x] T006 [P] Implement BEAM operations test (process spawn, message passing) in demo/lib/demo.ex
- [x] T007 Implement health_check/0 function combining all verifications in demo/lib/demo.ex
- [x] T008 Configure Mix release with include_erts in demo/mix.exs

**Checkpoint**: Demo app ready - workflow implementation can begin

---

## Phase 3: User Story 1 - Verify Release with Demo App (Priority: P1)

**Goal**: Maintainer can verify a specific OTP release works with a real Elixir application

**Independent Test**: Trigger workflow with valid tag (e.g., OTP-27.2), verify demo builds, starts, and passes health check

### Implementation for User Story 1

- [x] T009 [US1] Create e2e-test.yml workflow skeleton with workflow_dispatch trigger at .github/workflows/e2e-test.yml
- [x] T010 [US1] Add release_tag input parameter with validation in .github/workflows/e2e-test.yml
- [x] T011 [US1] Implement static Erlang package download step using gh release download in .github/workflows/e2e-test.yml
- [x] T012 [US1] Extract static Erlang to /opt/erlang in workflow at .github/workflows/e2e-test.yml
- [x] T013 [US1] Add Elixir installation step in workflow at .github/workflows/e2e-test.yml
- [x] T014 [US1] Add demo app build step (mix deps.get, mix release) in .github/workflows/e2e-test.yml
- [x] T015 [US1] Add demo app health check execution step in .github/workflows/e2e-test.yml
- [x] T016 [US1] Add functional verification step running all demo tests in .github/workflows/e2e-test.yml

**Checkpoint**: User Story 1 complete - workflow can verify single architecture releases

---

## Phase 4: User Story 2 - Multi-Architecture Validation (Priority: P2)

**Goal**: Maintainer can ensure release works on both amd64 and arm64 architectures

**Independent Test**: Run workflow, verify both architecture jobs run and report status independently

### Implementation for User Story 2

- [x] T017 [US2] Convert workflow to matrix strategy with amd64/arm64 in .github/workflows/e2e-test.yml
- [x] T018 [US2] Configure ubuntu-latest runner for amd64 in .github/workflows/e2e-test.yml
- [x] T019 [US2] Configure ubuntu-24.04-arm runner for arm64 in .github/workflows/e2e-test.yml
- [x] T020 [US2] Parameterize package download URL with architecture variable in .github/workflows/e2e-test.yml
- [x] T021 [US2] Add per-architecture status output in .github/workflows/e2e-test.yml

**Checkpoint**: User Story 2 complete - both architectures tested in parallel

---

## Phase 5: User Story 3 - Failure Reporting (Priority: P3)

**Goal**: Maintainer gets clear feedback when release has issues

**Independent Test**: Use invalid tag or break demo app, verify clear error messages appear

### Implementation for User Story 3

- [x] T022 [US3] Add release tag validation step to fail early on invalid format in .github/workflows/e2e-test.yml
- [x] T023 [US3] Add continue-on-error with explicit failure capture for download step in .github/workflows/e2e-test.yml
- [x] T024 [US3] Add error message output when release not found in .github/workflows/e2e-test.yml
- [x] T025 [US3] Enable verbose logging on demo app startup in .github/workflows/e2e-test.yml
- [x] T026 [US3] Add step to capture and display demo app logs on failure in .github/workflows/e2e-test.yml
- [x] T027 [US3] Add job summary with per-architecture pass/fail status in .github/workflows/e2e-test.yml

**Checkpoint**: User Story 3 complete - clear failure diagnostics available

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Improvements that affect multiple user stories

- [x] T028 [P] Add ExUnit tests for demo app in demo/test/demo_test.exs
- [x] T029 [P] Update README.md with e2e workflow usage instructions
- [x] T030 Validate workflow against quickstart.md local test steps
- [ ] T031 Test with actual OTP-27.2 release to verify end-to-end

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup - BLOCKS all user stories
- **User Story 1 (Phase 3)**: Depends on Foundational
- **User Story 2 (Phase 4)**: Depends on User Story 1 (extends the workflow)
- **User Story 3 (Phase 5)**: Depends on User Story 2 (adds error handling)
- **Polish (Phase 6)**: Depends on all user stories complete

### User Story Dependencies

- **User Story 1 (P1)**: Requires demo app from Foundational phase
- **User Story 2 (P2)**: Extends US1 workflow with matrix strategy
- **User Story 3 (P3)**: Adds error handling to US2 workflow

Note: For this feature, user stories build on each other since they all modify the same workflow file. They cannot be done in parallel.

### Within Each User Story

- Workflow structure before download steps
- Download steps before build steps
- Build steps before test steps

### Parallel Opportunities

Within Phase 2 (Foundational):
```bash
# T004, T005, T006 can run in parallel (different functions in same file):
Task: "Implement crypto verification function"
Task: "Implement SSL/TLS verification function"
Task: "Implement BEAM operations test"
```

Within Phase 6 (Polish):
```bash
# T028, T029 can run in parallel (different files):
Task: "Add ExUnit tests in demo/test/demo_test.exs"
Task: "Update README.md with e2e workflow usage"
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Phase 1: Setup (T001-T003)
2. Complete Phase 2: Foundational (T004-T008)
3. Complete Phase 3: User Story 1 (T009-T016)
4. **STOP and VALIDATE**: Test with single architecture manually
5. Can demo basic e2e verification capability

### Incremental Delivery

1. MVP (US1): Single architecture e2e test works
2. Add US2: Both architectures tested
3. Add US3: Clear error messages on failure
4. Polish: Documentation and final validation

### Task Summary

| Phase | Tasks | Parallel Opportunities |
|-------|-------|----------------------|
| Setup | 3 | 1 (T003) |
| Foundational | 5 | 3 (T004-T006) |
| User Story 1 | 8 | 0 (sequential workflow) |
| User Story 2 | 5 | 0 (sequential workflow) |
| User Story 3 | 6 | 0 (sequential workflow) |
| Polish | 4 | 2 (T028-T029) |
| **Total** | **31** | **6** |

---

## Notes

- Demo app uses only Erlang stdlib (:crypto, :ssl, :httpc) - no external Elixir deps
- Health check uses `bin/demo eval` not HTTP endpoint
- Static ERTS path must be `/opt/erlang/lib/erlang`
- Matrix builds run amd64 and arm64 in parallel
- Commit after each logical group of tasks
