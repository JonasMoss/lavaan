test_that("FMG parser accepts the initial single-model test set", {
  tests <- fmg_single_model_tests()

  parsed <- lapply(tests, lav_test_fmg_parse)

  expect_equal(vapply(parsed, `[[`, character(1L), "method"),
               c("std", "std", "peba", "peba", "peba", "peba",
                 "eba", "pols", "sb", "sb", "ss", "sf", "all",
                 "pall"))
  expect_equal(vapply(parsed, `[[`, logical(1L), "unbiased"),
               c(FALSE, FALSE, FALSE, FALSE, TRUE, FALSE, FALSE,
                 FALSE, FALSE, TRUE, FALSE, FALSE, FALSE, FALSE))
  expect_equal(vapply(parsed, `[[`, character(1L), "chisq"),
               c("ml", "rls", "rls", "rls", "rls", "rls", "rls",
                 "ml", "rls", "rls", "rls", "rls", "rls", "rls"))
})

test_that("lavTest single-model FMG p-values match semTests", {
  fmg_skip_if_no_semtests_reference()

  fit <- fmg_hs_fit()
  fmg_expect_semtests_parity(fit)
})

test_that("lavTest grouped FMG p-values match semTests", {
  fmg_skip_if_no_semtests_reference()

  fit <- fmg_hs_fit(group = "school")
  fmg_expect_semtests_parity(fit)
})

test_that("lavTest meanstructure FMG p-values match semTests", {
  fmg_skip_if_no_semtests_reference()

  fit <- fmg_hs_fit(meanstructure = TRUE)
  fmg_expect_semtests_parity(fit)
})

test_that("lavaan fit-time FMG tests populate the test slot", {
  fmg_skip_if_no_semtests_reference()

  tests <- c("peba4_rls", "peba4_ug_rls", "pols2_ml", "sb_rls")
  fit <- fmg_hs_fit(test = tests)

  expect_true(all(tests %in% names(fit@test)))
  expect_equal(
    fmg_fit_slot_pvalues(fit, tests),
    fmg_reference_pvalues(fit, tests),
    tolerance = 1e-7,
    ignore_attr = TRUE
  )
})

test_that("fitMeasures one-model FMG p-values match semTests", {
  fmg_skip_if_no_semtests_reference()

  tests <- fmg_single_model_tests()

  # The tests are intentionally requested through fm.args instead of changing
  # fitMeasures() defaults; this keeps the one-model API explicit.
  fmg_expect_fitmeasures_semtests_parity(
    fit = fmg_hs_fit(),
    tests = tests
  )

  fmg_expect_fitmeasures_semtests_parity(
    fit = fmg_hs_fit(test = tests),
    tests = tests
  )
})
