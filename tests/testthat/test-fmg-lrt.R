test_that("lavTestLRT explicit nested FMG gamma and chisq combinations match semTests", {
  fmg_skip_if_no_semtests_reference()

  fits <- fmg_hs_nested_fits()
  tests <- fmg_nested_gamma_chisq_tests()
  pvalues <- fmg_lavtest_lrt_pvalues(
    fits$restricted,
    fits$unrestricted,
    tests
  )

  expect_equal(
    pvalues,
    fmg_reference_nested_pvalues(
      fits$restricted,
      fits$unrestricted,
      tests
    ),
    tolerance = 1e-7,
    ignore_attr = TRUE
  )
  fmg_expect_gamma_chisq_combinations_differ(
    pvalues,
    methods = fmg_nested_gamma_chisq_methods()
  )
})

test_that("lavTestLRT FMG rejects method = 'satorra.bentler.2001'", {
  fits <- fmg_hs_nested_fits()

  expect_error(
    lavaan::lavTestLRT(
      fits$restricted,
      fits$unrestricted,
      method = "satorra.bentler.2001",
      test = "pall_ml"
    ),
    "not available for FMG nested tests"
  )
})

test_that("lavTestLRT method aliases use the FMG nested 2000 path", {
  fmg_skip_if_no_semtests_reference()

  fits <- fmg_hs_nested_fits()
  tests <- c("pall_ml", "peba4_ug_rls")

  expect_equal(
    fmg_lavtest_lrt_pvalues(
      fits$restricted,
      fits$unrestricted,
      tests,
      method = "default"
    ),
    fmg_lavtest_lrt_pvalues(fits$restricted, fits$unrestricted, tests),
    tolerance = 1e-7,
    ignore_attr = TRUE
  )
  expect_equal(
    fmg_lavtest_lrt_pvalues(
      fits$restricted,
      fits$unrestricted,
      tests,
      method = "standard"
    ),
    fmg_lavtest_lrt_pvalues(fits$restricted, fits$unrestricted, tests),
    tolerance = 1e-7,
    ignore_attr = TRUE
  )
})

test_that("suffixless nested FMG tests use model options", {
  fmg_skip_if_no_semtests_reference()

  reference_fits <- fmg_hs_nested_fits()
  methods <- fmg_nested_gamma_chisq_methods()
  cases <- list(
    list(suffix = "_ml", fit.args = list()),
    list(suffix = "_rls",
         fit.args = list(scaled.test = "browne.residual.nt.model")),
    list(suffix = "_ug_ml",
         fit.args = list(gamma.unbiased = TRUE)),
    list(suffix = "_ug_rls",
         fit.args = list(
           scaled.test = "browne.residual.nt.model",
           gamma.unbiased = TRUE
         ))
  )

  for (case in cases) {
    fits <- do.call(fmg_hs_nested_fits, case$fit.args)
    pvalues <- fmg_lavtest_lrt_pvalues(
      fits$restricted,
      fits$unrestricted,
      methods
    )

    expect_equal(
      pvalues,
      stats::setNames(
        fmg_reference_nested_pvalues(
          reference_fits$restricted,
          reference_fits$unrestricted,
          paste0(methods, case$suffix)
        ),
        methods
      ),
      tolerance = 1e-7,
      ignore_attr = TRUE
    )
  }
})

test_that("lavTestLRT meanstructure nested FMG p-values match semTests using method 2000", {
  fmg_skip_if_no_semtests_reference()

  fits <- fmg_hs_nested_fits(meanstructure = TRUE)

  fmg_expect_nested_semtests_parity(
    restricted = fits$restricted,
    unrestricted = fits$unrestricted,
    semtests_method = "2000",
    lrt_method = "satorra.2000"
  )
})

test_that("lavTestLRT grouped nested FMG p-values match semTests using method 2000", {
  fmg_skip_if_no_semtests_reference()

  fits <- fmg_hs_grouped_nested_fits()
  pvalues <- fmg_lavtest_lrt_pvalues(
    fits$restricted,
    fits$unrestricted,
    fmg_nested_gamma_chisq_tests()
  )

  expect_equal(
    pvalues,
    fmg_reference_nested_pvalues(
      fits$restricted,
      fits$unrestricted,
      fmg_nested_gamma_chisq_tests()
    ),
    tolerance = 1e-7,
    ignore_attr = TRUE
  )
  fmg_expect_gamma_chisq_combinations_differ(
    pvalues,
    methods = fmg_nested_gamma_chisq_methods()
  )
})

test_that("suffixless grouped nested FMG tests use model options", {
  fmg_skip_if_no_semtests_reference()

  reference_fits <- fmg_hs_grouped_nested_fits()
  methods <- fmg_nested_gamma_chisq_methods()
  cases <- list(
    list(suffix = "_ml", fit.args = list()),
    list(suffix = "_rls",
         fit.args = list(scaled.test = "browne.residual.nt.model")),
    list(suffix = "_ug_ml",
         fit.args = list(gamma.unbiased = TRUE)),
    list(suffix = "_ug_rls",
         fit.args = list(
           scaled.test = "browne.residual.nt.model",
           gamma.unbiased = TRUE
         ))
  )

  for (case in cases) {
    fits <- do.call(fmg_hs_grouped_nested_fits, case$fit.args)
    pvalues <- fmg_lavtest_lrt_pvalues(
      fits$restricted,
      fits$unrestricted,
      methods
    )

    expect_equal(
      pvalues,
      stats::setNames(
        fmg_reference_nested_pvalues(
          reference_fits$restricted,
          reference_fits$unrestricted,
          paste0(methods, case$suffix)
        ),
        methods
      ),
      tolerance = 1e-7,
      ignore_attr = TRUE
    )
  }
})

test_that("lavTestLRT nested FMG p-values are invariant to model order", {
  fmg_skip_if_no_semtests_reference()

  fits <- fmg_hs_nested_fits()
  tests <- fmg_nested_gamma_chisq_tests()

  expect_equal(
    fmg_lavtest_lrt_pvalues(fits$restricted, fits$unrestricted, tests),
    fmg_lavtest_lrt_pvalues(fits$unrestricted, fits$restricted, tests),
    tolerance = 1e-7,
    ignore_attr = TRUE
  )
})

test_that("lavTestLRT nested FMG rejects same-df comparisons", {
  fits <- fmg_hs_nested_fits()

  expect_error(
    lavaan::lavTestLRT(
      fits$unrestricted,
      fits$unrestricted,
      method = "satorra.2000",
      test = "pall_ml"
    ),
    "same degrees of freedom"
  )
})

test_that("lavTestLRT nested FMG traditional approximations are outside the supported surface", {
  fits <- fmg_hs_nested_fits()

  for (test in c("sb_ml", "ss_ml", "sf_ml")) {
    expect_error(
      lavaan::lavTestLRT(
        fits$restricted,
        fits$unrestricted,
        method = "satorra.2000",
        test = test
      ),
      "FMG nested tests support"
    )
  }
})
