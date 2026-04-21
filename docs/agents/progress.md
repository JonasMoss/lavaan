# Progress Report

Last updated: 2026-04-21.

## Repository State

- Branch: `semTests`.
- Rebases onto `origin/master` at `2881038c`.
- Local commits after rebase:
  - `155cd81c Add FMG p-value integration and parity tests`
  - `5d51e04c Clean up FMG API and Imhof integration`
  - `0a3d0202 Add FMG gamma combination parity tests`
- Current modified tracked files:
  - `docs/agents/progress.md`
  - `docs/agents/roadmap.md`
  - `docs/fmg/fmg-demo.qmd`
- Current untracked local files/directories:
  - `.codex`
  - `docs/agents/recomputation.md`
  - `docs/fmg/fmg-demo.html`
  - `semTests/`

## Completed Or Started

- `DESCRIPTION` temporarily adds `testthat` to `Suggests` for local parity
  testing. The earlier `CompQuadForm` runtime import has been removed after
  adding a pure R Imhof helper.
- `R/lav_test.R` recognizes FMG-style test strings during validation and
  ordering.
- `R/lav_options.R` allows FMG-style names through final `test` option
  validation.
- `R/lav_test.R` dispatches FMG test names from `lav_model_test()` into
  `lav_test_fmg()`.
- `R/lav_test_LRT.R` has a narrow FMG branch for nested-model comparisons via
  `lavTestLRT(..., test = "<fmg-test>")`. Only `method = "satorra.2000"` (and
  the `"default"` / `"standard"` aliases) is accepted; the FMG nested path now
  rejects `method = "satorra.bentler.2001"` explicitly because the
  scaled-and-shifted style semTests `"2001"` reference does not line up with
  lavaan's SB-2001 mean-only nested test.
- `tests/testthat/` contains temporary tests comparing the initial single-model
  FMG test set against the local semTests reference implementation. Coverage
  currently includes ungrouped, grouped, and meanstructure Holzinger-Swineford
  fits for standard, RLS, pEBA, EBA, pOLS, SB, scaled-and-shifted, scaled-F,
  ALL, and PALL p-values.
- One-model `fitMeasures()` coverage uses
  `fm.args = list(standard.test = "<fmg-test>")` and checks both on-demand
  computation and fit-time computed FMG entries against semTests.
- Nested test coverage is intentionally focused on FMG eigenvalue methods, not
  SB-style nested tests. It now covers the full supported nested biased/unbiased
  Gamma by ML/RLS chi-square matrix for `pall`, `all`, `peba4`, `eba2`, and
  `pols2` against semTests method `"2000"` for ungrouped, grouped, and
  meanstructure Holzinger-Swineford comparisons. The nested suite also checks
  suffixless option-driven requests, model-order invariance, method aliases,
  same-df rejection, `method = "satorra.bentler.2001"` rejection, and the
  explicit nested unsupported-surface errors for `sb`, `ss`, and `sf`.
- `Justfile` contains local iteration recipes for testthat, build, check, and
  status commands.
- `docs/fmg/fmg-demo.qmd` demonstrates current one-model and nested FMG usage,
  records implementation notes, and renders to `docs/fmg/fmg-demo.html`.
- `R/lav_test_fmg.R` contains a draft implementation for:
  - FMG test-name detection and parsing.
  - A pure R Imhof integration helper for quadratic-form p-values.
  - Single-model FMG p-values: pEBA, EBA, pOLS, PALL, ALL, SB, scaled and
    shifted, scaled F, and standard chi-square.
  - UGamma construction with an optional unbiased Gamma path.
  - Nested-model FMG p-values for PALL, ALL, pEBA, EBA, and pOLS, plus nested
    UGamma helpers.
- The clean API now uses suffixless FMG names plus existing lavaan options:
  `test = "peba4"` uses ML by default, `scaled.test =
  "browne.residual.nt.model"` selects the RLS statistic, and
  `gamma.unbiased = TRUE` selects the unbiased Gamma estimator. The old
  semTests-style suffix strings remain accepted as a compatibility layer.
- New regression tests compare `gamma.unbiased = TRUE` against semTests `_ug`
  references for one-model and nested FMG p-values, and assert biased and
  unbiased p-values are not silently identical.
- One-model regression tests now cover the full biased/unbiased Gamma by
  ML/RLS chi-square matrix for `peba4`, `eba2`, `pols2`, `sb`, `ss`, `sf`,
  `all`, and `pall` through both explicit suffixed `lavTest()` requests and
  fit-time `lavaan(..., test = ...)` requests. The semTests `_ug` expectations
  deliberately use a biased-Gamma lavaan reference fit because semTests derives
  its unbiased Gamma from the fitted object's available Gamma matrix.
- Nested regression tests use the same biased-Gamma reference rule for semTests
  `_ug` expectations, including when lavaan suffixless requests are driven by
  `gamma.unbiased = TRUE` on the fitted restricted and unrestricted objects.
- After rebasing onto current lavaan, FMG was adapted to upstream snake_case
  internals (`lav_samplestats_gamma()`, `lav_test_diff_a()`). The new fast
  Browne NT path now falls back to `MASS::ginv()` if the Cholesky inversion
  fails, which preserves grouped RLS cases used by the semTests reference.
  The grouped Holzinger-Swineford RLS tests enter this fast path for the
  unrestricted model; the projection matrix `A` is rank-deficient (`rank = 30`
  for a 60 by 60 matrix in each group), so the old plain `chol(A)` path fails.
- The local `semTests/` checkout is available as reference source, including
  `R/pvalues.R`, `R/tests.R`, and `R/gamma.R`.

## Known Gaps

- The temporary testthat harness should be removed or revised before preparing
  an upstream pull request unless maintainers decide to adopt testthat.

## Immediate Next Steps

1. Decide whether to add user-facing documentation for
   `fitMeasures(..., fm.args = list(standard.test = "<fmg-test>"))` or keep FMG
   p-values exposed through `lavTest()` only for now.
2. Prepare PR-readiness cleanup: decide whether to keep temporary testthat,
   remove local-only agent docs from the branch, and keep or drop the Justfile.
3. Use `docs/fmg/fmg-demo.qmd` as the starting point for package-facing Rd or
   vignette documentation in the next iteration.

## Latest Test Run

Command: `just test`

Result: passed.

- Parser coverage passed for the broader single-model test set.
- `lavTest()` p-values match semTests for ungrouped, grouped, and
  meanstructure Holzinger-Swineford fits.
- Fit-time `lavaan(..., test = ...)` entries populate `@test` and match
  semTests for the checked cases.
- Explicit suffixed one-model tests now verify all four Gamma/chisq
  combinations (`*_ml`, `*_rls`, `*_ug_ml`, `*_ug_rls`) for the main FMG
  methods, and assert that the four p-values are not collapsing to identical
  results within each method.
- Suffixless one-model `lavTest()` and fit-time requests now verify the
  supported option-driven methods (`peba4`, `eba2`, `pols2`, `all`, `pall`)
  under biased ML, biased RLS, unbiased ML, and unbiased RLS settings against
  the corresponding semTests suffixed references.
- `fitMeasures(..., fm.args = list(standard.test = "<fmg-test>"))` p-values
  match semTests for the checked one-model cases, whether the FMG test was
  computed on demand or at fit time.
- `lavTestLRT(..., test = ...)` nested p-values match semTests for the full
  supported nested FMG method matrix (`pall`, `all`, `peba4`, `eba2`, and
  `pols2` crossed with `*_ml`, `*_rls`, `*_ug_ml`, and `*_ug_rls`) for
  ungrouped, grouped, and meanstructure Holzinger-Swineford comparisons under
  method `"2000"`.
- Nested suffixless `lavTestLRT()` requests now verify biased ML, biased RLS,
  unbiased ML, and unbiased RLS settings against the corresponding semTests
  suffixed references. Nested tests also cover method aliases, model-order
  invariance, same-df rejection, `method = "satorra.bentler.2001"` rejection,
  and unsupported nested `sb`, `ss`, and `sf` errors.
- Grouped RLS coverage exercises the Browne NT fast-path singular-`A` fallback
  in `R/lav_test_browne.R`: grouped unrestricted models have rank-deficient
  `A`, so `MASS::ginv(A) %*% b` is required when `chol(A)` fails.
- The pure R Imhof helper removed the previous `CompQuadForm::imhof()`
  numerical-integration warnings in the local testthat suite.
- `quarto render docs/fmg/fmg-demo.qmd` completed successfully.
- `R CMD build .` completed and produced `lavaan_0.6-22.2560.tar.gz`.
- `R CMD check lavaan_0.6-22.2560.tar.gz` completed with `Status: OK`.
- `R CMD check .` is not the right local check command for this checkout
  because it fails before code checks with missing `Author`/`Maintainer`
  fields; checking the built tarball works because `R CMD build` materializes
  those fields from `Authors@R`.
