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
