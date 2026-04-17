# Roadmap

## Goal

Integrate the improved goodness-of-fit p-value methods from semTests into
lavaan core with minimal new machinery and a lavaan-native API.

Reference methods:

- pEBA: penalized eigenvalue block averaging.
- EBA: eigenvalue block averaging.
- pOLS: penalized OLS regression on UGamma eigenvalues.
- PALL/ALL: all-eigenvalue variants, with PALL as the preferred nested-model
  option.
- Optional unbiased Gamma correction following Du and Bentler.

## Phase 1: Stabilize Single-Model Tests

- Add temporary testthat parity tests against the local semTests reference.
- Verify parser behavior for names such as `peba4_rls`, `peba4_ug_rls`,
  `pols2_ml`, `eba2`, `sb_ug`, `ss_rls`, `sf_rls`, and `std_ml`.
- Allow FMG names through the final `lav_options_set()` `test` validation with
  the smallest possible `R/lav_options.R` change.
- Add `lav_model_test()` dispatch for FMG test names after standard/nonstandard
  chi-square statistics are available.
- Ensure RLS-based FMG tests can reuse the Browne residual statistic without
  recursive or duplicate test-slot surprises.
- Confirm Gamma and UGamma paths work for ML/MLM-style fits and fail clearly
  otherwise.
- Compare p-values to semTests for representative one-model examples.

## Phase 2: Unbiased Gamma

- Audit the current unbiased Gamma draft against `semTests/R/gamma.R`.
- Confirm meanstructure, grouped data, and sample-size scaling behavior.
- Decide whether the public option should remain encoded in test names
  (`*_ug_*`) or also expose an internal numeric `unbiased` mode:
  biased only, unbiased only, or both.
- Add regression examples or tests for biased versus unbiased Gamma output.

## Phase 3: Nested Tests

- Wire `lav_test_fmg_nested()` into the nested-model workflow, likely through
  `lavTestLRT()` or the same path used by existing robust difference tests.
- Validate model ordering, equal-df errors, Satorra 2000 fallback behavior, and
  negative-eigenvalue handling.
- Keep the nested scope focused on FMG eigenvalue methods, not SB-style nested
  tests: PALL, ALL, pEBA, and EBA under methods `"2000"` and `"2001"`.
- Compare `pall_ug_ml`, `all_ml`, `peba4_*`, and `eba2_*` style results to
  semTests reference outputs.
- Keep pOLS outside the nested supported surface for now; `lavTestLRT()` should
  fail explicitly for nested `pols*` tests instead of silently falling back to
  another method.
- Match semTests group-weight scaling for the full nested method-2000 UGamma
  matrix. In the grouped path, Gamma blocks are rescaled by `1 / fg`, while
  WLS.V blocks are weighted by `fg`; this is needed for eigenvalue parity and
  differs from trace-only simplifications in lavaan's existing robust
  difference-test code.

## Phase 4: User-Facing Surfaces

- Confirm `lavaan(..., test = "peba4_rls")` populates the `@test` slot.
- Confirm `lavTest(fit, test = "peba4_rls")` works when the fit did not request
  the test at fit time.
- For the current minimal one-model surface, expose `fitMeasures()` p-values
  through the existing selected-test mechanism:
  `fitMeasures(fit, "pvalue", fm.args = list(standard.test = "peba4_rls"))`.
- Decide separately whether named FMG-specific fit measures are worth adding.
- Update Rd documentation only after the API shape is stable.

## Phase 5: Package Quality

- Add focused lavaan-side tests or examples.
- Run the narrow examples used for semTests parity.
- Run `R CMD build .` and check the resulting tarball with
  `R CMD check lavaan_*.tar.gz`.
- Remove or quarantine any local reference artifacts that should not be part of
  the lavaan branch.
