test_that("lavTestLRT nested FMG p-values match semTests using method 2000", {
  fmg_skip_if_no_semtests_reference()

  fits <- fmg_hs_nested_fits()

  fmg_expect_nested_semtests_parity(
    restricted = fits$restricted,
    unrestricted = fits$unrestricted
  )
})

test_that("lavTestLRT nested FMG p-values match semTests using method 2001", {
  fmg_skip_if_no_semtests_reference()

  fits <- fmg_hs_nested_fits()

  fmg_expect_nested_semtests_parity(
    restricted = fits$restricted,
    unrestricted = fits$unrestricted,
    semtests_method = "2001",
    lrt_method = "satorra.bentler.2001"
  )
})

test_that("gamma.unbiased option reaches nested FMG UGamma computation", {
  fmg_skip_if_no_semtests_reference()

  fits_biased <- fmg_hs_nested_fits()
  fits_unbiased <- fmg_hs_nested_fits(gamma.unbiased = TRUE)

  option_tests <- c("peba4_ml", "peba4_rls")
  suffix_tests <- c("peba4_ug_ml", "peba4_ug_rls")

  expect_equal(
    fmg_lavtest_lrt_pvalues(
      fits_unbiased$restricted,
      fits_unbiased$unrestricted,
      option_tests
    ),
    stats::setNames(
      fmg_reference_nested_pvalues(
        fits_biased$restricted,
        fits_biased$unrestricted,
        suffix_tests
      ),
      option_tests
    ),
    tolerance = 1e-7,
    ignore_attr = TRUE
  )
  expect_false(isTRUE(all.equal(
    fmg_lavtest_lrt_pvalues(
      fits_biased$restricted,
      fits_biased$unrestricted,
      option_tests
    ),
    fmg_lavtest_lrt_pvalues(
      fits_unbiased$restricted,
      fits_unbiased$unrestricted,
      option_tests
    ),
    tolerance = 1e-12,
    check.attributes = FALSE
  )))
})

test_that("suffixless nested FMG tests use model options", {
  fmg_skip_if_no_semtests_reference()

  fits_ml <- fmg_hs_nested_fits()
  fits_rls <- fmg_hs_nested_fits(scaled.test = "browne.residual.nt.model")
  fits_ug_ml <- fmg_hs_nested_fits(gamma.unbiased = TRUE)
  fits_ug_rls <- fmg_hs_nested_fits(
    scaled.test = "browne.residual.nt.model",
    gamma.unbiased = TRUE
  )

  p_ml <- fmg_lavtest_lrt_pvalues(
    fits_ml$restricted, fits_ml$unrestricted, "peba4"
  )
  p_rls <- fmg_lavtest_lrt_pvalues(
    fits_rls$restricted, fits_rls$unrestricted, "peba4"
  )
  p_ug_ml <- fmg_lavtest_lrt_pvalues(
    fits_ug_ml$restricted, fits_ug_ml$unrestricted, "peba4"
  )
  p_ug_rls <- fmg_lavtest_lrt_pvalues(
    fits_ug_rls$restricted, fits_ug_rls$unrestricted, "peba4"
  )

  expect_equal(
    p_ml,
    stats::setNames(
      fmg_reference_nested_pvalues(
        fits_ml$restricted, fits_ml$unrestricted, "peba4_ml"
      ),
      "peba4"
    ),
    tolerance = 1e-7,
    ignore_attr = TRUE
  )
  expect_equal(
    p_rls,
    stats::setNames(
      fmg_reference_nested_pvalues(
        fits_rls$restricted, fits_rls$unrestricted, "peba4_rls"
      ),
      "peba4"
    ),
    tolerance = 1e-7,
    ignore_attr = TRUE
  )
  expect_equal(
    p_ug_ml,
    stats::setNames(
      fmg_reference_nested_pvalues(
        fits_ml$restricted, fits_ml$unrestricted, "peba4_ug_ml"
      ),
      "peba4"
    ),
    tolerance = 1e-7,
    ignore_attr = TRUE
  )
  expect_equal(
    p_ug_rls,
    stats::setNames(
      fmg_reference_nested_pvalues(
        fits_rls$restricted, fits_rls$unrestricted, "peba4_ug_rls"
      ),
      "peba4"
    ),
    tolerance = 1e-7,
    ignore_attr = TRUE
  )
})

test_that("lavTestLRT grouped nested FMG p-values match semTests using method 2001", {
  fmg_skip_if_no_semtests_reference()

  unrestricted <- lavaan::cfa(
    fmg_hs_model(),
    data = lavaan::HolzingerSwineford1939,
    group = "school",
    estimator = "MLM"
  )
  restricted <- lavaan::cfa(
    fmg_hs_model(),
    data = lavaan::HolzingerSwineford1939,
    group = "school",
    group.equal = "loadings",
    estimator = "MLM"
  )

  fmg_expect_nested_semtests_parity(
    restricted = restricted,
    unrestricted = unrestricted,
    semtests_method = "2001",
    lrt_method = "satorra.bentler.2001"
  )
})

test_that("lavTestLRT grouped nested FMG p-values match semTests using method 2000", {
  fmg_skip_if_no_semtests_reference()

  unrestricted <- lavaan::cfa(
    fmg_hs_model(),
    data = lavaan::HolzingerSwineford1939,
    group = "school",
    estimator = "MLM"
  )
  restricted <- lavaan::cfa(
    fmg_hs_model(),
    data = lavaan::HolzingerSwineford1939,
    group = "school",
    group.equal = "loadings",
    estimator = "MLM"
  )

  fmg_expect_nested_semtests_parity(
    restricted = restricted,
    unrestricted = unrestricted,
    semtests_method = "2000",
    lrt_method = "satorra.2000"
  )
})

test_that("lavTestLRT nested FMG pOLS is outside the supported surface", {
  fits <- fmg_hs_nested_fits()

  expect_error(
    lavaan::lavTestLRT(
      fits$restricted,
      fits$unrestricted,
      method = "satorra.2000",
      test = "pols2_ml"
    ),
    "FMG nested tests support"
  )
})
