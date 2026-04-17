# Agent Rules

These rules apply to coding agents working in this lavaan checkout.

## Scope

- Prefer small, reviewable patches that match lavaan's existing style.
- Keep semTests integration code inside lavaan modules. Do not add a runtime
  dependency on the local `semTests/` checkout.
- Treat `semTests/` as reference code only unless explicitly asked to edit it.
- Do not move or delete user-created local files without explicit permission.

## R Package Constraints

- Keep new runtime dependencies minimal. FMG p-values now use the internal
  pure R Imhof helper in `R/lav_test_fmg.R` instead of adding `CompQuadForm`.
- Avoid adding dependency-heavy helpers from semTests such as `RSpectra` unless
  a clear performance need is demonstrated.
- Preserve compatibility with lavaan's current R dependency unless the
  maintainers explicitly raise it.
- Keep internal helpers unexported unless there is a documented user-facing API.

## Implementation Style

- Reuse existing lavaan APIs such as `lavTech()`, `lavInspect()`,
  `lav_test_satorra_bentler()`, `lav_test_diff_A()`, `lav_matrix_bdiag()`, and
  `lav_samplestats_Gamma()` where possible.
- Keep user-facing test names normalized through `lav_test_rename()`.
- Make `lav_model_test()` the source of truth for test-slot entries at fit time
  and through `lavTest()`.
- Preserve the standard lavaan test-list shape: each test entry should contain
  `test`, `stat`, `stat.group` when applicable, `df`, `refdistr`, and `pvalue`.
- For unsupported estimators or missing Gamma/UGamma inputs, fail with lavaan
  message helpers and clear guidance.

## Validation

- This branch intentionally uses temporary `testthat` tests for fast local
  iteration. Remove `testthat` from `DESCRIPTION`, remove `tests/testthat*`,
  and remove or revise the Justfile before preparing an upstream pull request
  unless lavaan maintainers explicitly want to keep them.
- Compare FMG p-values against the local semTests reference for simple ML,
  grouped, meanstructure, and nested-model examples.
- Exercise `lavaan(..., test = ...)`, `lavTest()`, `fitMeasures()`, and
  `lavTestLRT()` once integration reaches each entry point.
- Run a package build/check before presenting a broad implementation as done.

## Documentation Hygiene

- Keep this folder for agent coordination only. User-facing lavaan documentation
  belongs in `man/`, `README.md`, vignettes, or package help topics.
- Update `docs/agents/progress.md` whenever substantive implementation status
  changes.
- Update `docs/agents/roadmap.md` when priorities or accepted scope changes.
