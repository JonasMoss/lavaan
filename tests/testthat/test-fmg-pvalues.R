test_that("FMG parser accepts the initial single-model test set", {
  tests <- fmg_single_model_tests()

  parsed <- lapply(tests, lavaan:::lav_test_fmg_parse)

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

test_that("lavTest explicit FMG gamma and chisq combinations match semTests", {
  fmg_skip_if_no_semtests_reference()

  fit <- fmg_hs_fit()
  tests <- fmg_gamma_chisq_tests()
  pvalues <- fmg_lavtest_pvalues(fit, tests)

  expect_equal(
    pvalues,
    fmg_reference_pvalues(fit, tests),
    tolerance = 1e-7,
    ignore_attr = TRUE
  )
  fmg_expect_gamma_chisq_combinations_differ(pvalues)
})

test_that("lavaan fit-time explicit FMG gamma and chisq combinations match semTests", {
  fmg_skip_if_no_semtests_reference()

  reference_fit <- fmg_hs_fit()
  tests <- fmg_gamma_chisq_tests()
  fit <- fmg_hs_fit(test = tests)
  entries <- fit@test[tests]
  pvalues <- fmg_fit_slot_pvalues(fit, tests)

  expect_true(all(tests %in% names(fit@test)))
  expect_equal(
    pvalues,
    fmg_reference_pvalues(reference_fit, tests),
    tolerance = 1e-7,
    ignore_attr = TRUE
  )
  expect_equal(
    unname(vapply(entries, `[[`, logical(1L), "unbiased")),
    grepl("_ug_", tests)
  )
  expect_equal(
    unname(vapply(entries, `[[`, character(1L), "chisq.type")),
    ifelse(grepl("_rls$", tests), "rls", "ml")
  )
  fmg_expect_gamma_chisq_combinations_differ(pvalues)
})

test_that("suffixless lavTest FMG tests use gamma and chisq options", {
  fmg_skip_if_no_semtests_reference()

  reference_fit <- fmg_hs_fit()
  fits <- list(
    biased = reference_fit,
    unbiased = fmg_hs_fit(gamma.unbiased = TRUE)
  )
  methods <- fmg_suffixless_option_methods()
  cases <- list(
    list(fit = "biased", suffix = "_ml", lavtest.args = list(),
         unbiased = FALSE, chisq = "ml"),
    list(fit = "biased", suffix = "_rls",
         lavtest.args = list(scaled.test = "browne.residual.nt.model"),
         unbiased = FALSE, chisq = "rls"),
    list(fit = "unbiased", suffix = "_ug_ml", lavtest.args = list(),
         unbiased = TRUE, chisq = "ml"),
    list(fit = "unbiased", suffix = "_ug_rls",
         lavtest.args = list(scaled.test = "browne.residual.nt.model"),
         unbiased = TRUE, chisq = "rls")
  )

  for (case in cases) {
    entries <- do.call(
      fmg_lavtest_entries,
      c(list(fit = fits[[case$fit]], tests = methods), case$lavtest.args)
    )
    pvalues <- stats::setNames(
      vapply(entries, `[[`, numeric(1L), "pvalue"),
      methods
    )

    expect_equal(
      pvalues,
      stats::setNames(
        fmg_reference_pvalues(reference_fit, paste0(methods, case$suffix)),
        methods
      ),
      tolerance = 1e-7,
      ignore_attr = TRUE
    )
    expect_equal(
      unname(vapply(entries, `[[`, logical(1L), "unbiased")),
      rep(case$unbiased, length(methods))
    )
    expect_equal(
      unname(vapply(entries, `[[`, character(1L), "chisq.type")),
      rep(case$chisq, length(methods))
    )
  }
})

test_that("suffixless fit-time FMG tests use gamma and chisq options", {
  fmg_skip_if_no_semtests_reference()

  reference_fit <- fmg_hs_fit()
  methods <- fmg_suffixless_option_methods()
  cases <- list(
    list(suffix = "_ml", fit.args = list(),
         unbiased = FALSE, chisq = "ml"),
    list(suffix = "_rls",
         fit.args = list(scaled.test = "browne.residual.nt.model"),
         unbiased = FALSE, chisq = "rls"),
    list(suffix = "_ug_ml",
         fit.args = list(gamma.unbiased = TRUE),
         unbiased = TRUE, chisq = "ml"),
    list(suffix = "_ug_rls",
         fit.args = list(
           scaled.test = "browne.residual.nt.model",
           gamma.unbiased = TRUE
         ),
         unbiased = TRUE, chisq = "rls")
  )

  for (case in cases) {
    fit <- do.call(
      fmg_hs_fit,
      c(list(test = methods), case$fit.args)
    )
    entries <- fit@test[methods]

    expect_equal(
      fmg_fit_slot_pvalues(fit, methods),
      stats::setNames(
        fmg_reference_pvalues(reference_fit, paste0(methods, case$suffix)),
        methods
      ),
      tolerance = 1e-7,
      ignore_attr = TRUE
    )
    expect_equal(
      unname(vapply(entries, `[[`, logical(1L), "unbiased")),
      rep(case$unbiased, length(methods))
    )
    expect_equal(
      unname(vapply(entries, `[[`, character(1L), "chisq.type")),
      rep(case$chisq, length(methods))
    )
  }
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
