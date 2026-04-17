# Progress Report

Last updated: 2026-04-17.

## Repository State

- Branch: `semTests`.
- Baseline checkpoint: `e6045ffe Add FMG p-value integration and parity tests`.
- Current modified tracked files:
  - `R/lav_test.R`
  - `R/lav_test_LRT.R`
  - `R/lav_test_fmg.R`
  - `DESCRIPTION`
  - `docs/agents/rules.md`
  - `docs/fmg/fmg-demo.qmd`
  - `tests/testthat/test-fmg-lrt.R`
  - `tests/testthat/test-fmg-pvalues.R`
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
  `lavTestLRT(..., test = "<fmg-test>")`, mapping lavaan's
  `method = "satorra.2000"` to semTests method `"2000"` and
  `method = "satorra.bentler.2001"` to semTests method `"2001"`.
- `tests/testthat/` contains temporary tests comparing the initial single-model
  FMG test set against the local semTests reference implementation. Coverage
  currently includes ungrouped, grouped, and meanstructure Holzinger-Swineford
  fits for standard, RLS, pEBA, EBA, pOLS, SB, scaled-and-shifted, scaled-F,
  ALL, and PALL p-values.
- One-model `fitMeasures()` coverage uses
  `fm.args = list(standard.test = "<fmg-test>")` and checks both on-demand
  computation and fit-time computed FMG entries against semTests.
- Nested test coverage is intentionally focused on FMG eigenvalue methods, not
  SB-style nested tests. It currently includes ungrouped and grouped
  Holzinger-Swineford comparisons under semTests methods `"2000"` and `"2001"`
  for `pall_ug_ml`, `pall_ml`, `all_ml`,
  `peba4_ml`, `peba4_ug_ml`, `peba4_rls`, `peba4_ug_rls`, and `eba2_ml`.
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
  - Nested-model FMG p-values and nested UGamma helpers.
- The clean API now uses suffixless FMG names plus existing lavaan options:
  `test = "peba4"` uses ML by default, `scaled.test =
  "browne.residual.nt.model"` selects the RLS statistic, and
  `gamma.unbiased = TRUE` selects the unbiased Gamma estimator. The old
  semTests-style suffix strings remain accepted as a compatibility layer.
- New regression tests compare `gamma.unbiased = TRUE` against semTests `_ug`
  references for one-model and nested FMG p-values, and assert biased and
  unbiased p-values are not silently identical.
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
3. Nested pOLS is outside the supported surface for now; `lavTestLRT()` errors
   rather than silently using another nested p-value method.
4. Use `docs/fmg/fmg-demo.qmd` as the starting point for package-facing Rd or
   vignette documentation in the next iteration.

## Latest Test Run

Command: `just test`

Result: passed.

- Parser coverage passed for the broader single-model test set.
- `lavTest()` p-values match semTests for ungrouped, grouped, and
  meanstructure Holzinger-Swineford fits.
- Fit-time `lavaan(..., test = ...)` entries populate `@test` and match
  semTests for the checked cases.
- `fitMeasures(..., fm.args = list(standard.test = "<fmg-test>"))` p-values
  match semTests for the checked one-model cases, whether the FMG test was
  computed on demand or at fit time.
- `lavTestLRT(..., test = ...)` nested p-values match semTests for the scoped
  FMG eigenvalue methods: ungrouped and grouped Holzinger-Swineford comparisons
  under methods `"2000"` and `"2001"`.
- The pure R Imhof helper removed the previous `CompQuadForm::imhof()`
  numerical-integration warnings in the local testthat suite.
- `R CMD build .` completed and produced `lavaan_0.6-22.2469.tar.gz`.
- `R CMD check lavaan_0.6-22.2469.tar.gz` completed with `Status: OK`.
- `R CMD check .` is not the right local check command for this checkout
  because it fails before code checks with missing `Author`/`Maintainer`
  fields; checking the built tarball works because `R CMD build` materializes
  those fields from `Authors@R`.
