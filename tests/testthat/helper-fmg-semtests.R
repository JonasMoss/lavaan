fmg_semtests_root <- function() {
  root <- normalizePath(getwd(), mustWork = TRUE)
  while (!file.exists(file.path(root, "DESCRIPTION"))) {
    parent <- dirname(root)
    if (identical(parent, root)) {
      stop("could not locate lavaan package root", call. = FALSE)
    }
    root <- parent
  }
  file.path(root, "semTests")
}

fmg_skip_if_no_semtests_reference <- function() {
  testthat::skip_if_not(
    dir.exists(fmg_semtests_root()),
    "local semTests reference checkout is not available"
  )
}

fmg_semtests_reference <- local({
  ref <- NULL

  function() {
    fmg_skip_if_no_semtests_reference()

    if (!is.null(ref)) {
      return(ref)
    }

    ref <<- new.env(parent = globalenv())
    source_files <- file.path(
      fmg_semtests_root(),
      "R",
      c(
        "lavaan_helper.R",
        "derivatives.R",
        "get_a_matrix.R",
        "utility.R",
        "tests.R",
        "gamma.R",
        "pvalues.R"
      )
    )

    for (path in source_files) {
      source(path, local = ref)
    }

    ref
  }
})

fmg_hs_model <- function() {
  "
    visual  =~ x1 + x2 + x3
    textual =~ x4 + x5 + x6
    speed   =~ x7 + x8 + x9
  "
}

fmg_hs_fit <- function(...) {
  lavaan::cfa(
    fmg_hs_model(),
    data = lavaan::HolzingerSwineford1939,
    estimator = "MLM",
    ...
  )
}

fmg_hs_nested_model <- function() {
  "
    visual  =~ x1 + a*x2 + x3
    textual =~ x4 + a*x5 + a*x6
    speed   =~ x7 + a*x8 + x9
  "
}

fmg_hs_nested_fits <- function(...) {
  list(
    restricted = lavaan::cfa(
      fmg_hs_nested_model(),
      data = lavaan::HolzingerSwineford1939,
      estimator = "MLM",
      ...
    ),
    unrestricted = lavaan::cfa(
      fmg_hs_model(),
      data = lavaan::HolzingerSwineford1939,
      estimator = "MLM",
      ...
    )
  )
}

fmg_hs_grouped_nested_fits <- function(...) {
  list(
    restricted = lavaan::cfa(
      fmg_hs_model(),
      data = lavaan::HolzingerSwineford1939,
      group = "school",
      group.equal = "loadings",
      estimator = "MLM",
      ...
    ),
    unrestricted = lavaan::cfa(
      fmg_hs_model(),
      data = lavaan::HolzingerSwineford1939,
      group = "school",
      estimator = "MLM",
      ...
    )
  )
}

fmg_reference_pvalues <- function(fit, tests) {
  ref <- fmg_semtests_reference()
  stats::setNames(
    vapply(tests, function(test) {
      unname(ref$pvalues(fit, test)[[1L]])
    }, numeric(1L)),
    tests
  )
}

fmg_reference_nested_pvalues <- function(restricted, unrestricted, tests,
                                         method = "2000") {
  ref <- fmg_semtests_reference()
  stats::setNames(
    vapply(tests, function(test) {
      unname(ref$pvalues_nested(
        restricted, unrestricted,
        method = method,
        tests = test
      )[[1L]])
    }, numeric(1L)),
    tests
  )
}

fmg_lavtest_pvalues <- function(fit, tests) {
  stats::setNames(
    vapply(tests, function(test) {
      unname(lavaan::lavTest(fit, test = test)$pvalue)
    }, numeric(1L)),
    tests
  )
}

fmg_lavtest_lrt_pvalues <- function(restricted, unrestricted, tests,
                                    method = "satorra.2000") {
  stats::setNames(
    vapply(tests, function(test) {
      tab <- lavaan::lavTestLRT(
        restricted,
        unrestricted,
        method = method,
        test = test
      )
      unname(tab[2L, "Pr(>Chisq)"])
    }, numeric(1L)),
    tests
  )
}

fmg_fit_slot_pvalues <- function(fit, tests) {
  stats::setNames(
    vapply(fit@test[tests], `[[`, numeric(1L), "pvalue"),
    tests
  )
}

fmg_lavtest_entries <- function(fit, tests, ...) {
  out <- lavaan::lavTest(fit, test = tests, ...)
  if (!is.null(out$pvalue)) {
    stats::setNames(list(out), tests)
  } else {
    out[tests]
  }
}

fmg_fitmeasures_pvalues <- function(fit, tests) {
  stats::setNames(
    vapply(tests, function(test) {
      fm <- lavaan::fitMeasures(
        fit,
        fit.measures = c("chisq", "df", "pvalue"),
        fm.args = list(standard.test = test)
      )
      unname(fm[["pvalue"]])
    }, numeric(1L)),
    tests
  )
}

fmg_gamma_chisq_methods <- function() {
  c("peba4", "eba2", "pols2", "sb", "ss", "sf", "all", "pall")
}

fmg_suffixless_option_methods <- function() {
  c("peba4", "eba2", "pols2", "all", "pall")
}

fmg_gamma_chisq_suffixes <- function() {
  c("_ml", "_rls", "_ug_ml", "_ug_rls")
}

fmg_gamma_chisq_tests <- function(methods = fmg_gamma_chisq_methods()) {
  as.vector(outer(methods, fmg_gamma_chisq_suffixes(), paste0))
}

fmg_nested_gamma_chisq_methods <- function() {
  c("pall", "all", "peba4", "eba2", "pols2")
}

fmg_nested_gamma_chisq_tests <- function(
    methods = fmg_nested_gamma_chisq_methods()) {
  fmg_gamma_chisq_tests(methods)
}

fmg_expect_gamma_chisq_combinations_differ <- function(
    pvalues,
    methods = fmg_gamma_chisq_methods(),
    suffixes = fmg_gamma_chisq_suffixes()) {
  pvalue_matrix <- matrix(
    pvalues[paste0(rep(methods, times = length(suffixes)),
                   rep(suffixes, each = length(methods)))],
    nrow = length(methods),
    dimnames = list(methods, suffixes)
  )

  apply(pvalue_matrix, 1L, function(x) {
    testthat::expect_gt(min(abs(stats::dist(x))), 1e-10)
  })
  invisible(pvalue_matrix)
}

fmg_single_model_tests <- function() {
  c(
    "std_ml",
    "std_rls",
    "peba2_rls",
    "peba4_rls",
    "peba4_ug_rls",
    "peba6_rls",
    "eba2_rls",
    "pols2_ml",
    "sb_rls",
    "sb_ug_rls",
    "ss_rls",
    "sf_rls",
    "all_rls",
    "pall_rls"
  )
}

fmg_nested_model_tests <- function() {
  fmg_nested_gamma_chisq_tests()
}

fmg_expect_semtests_parity <- function(fit, tests = fmg_single_model_tests()) {
  testthat::expect_equal(
    fmg_lavtest_pvalues(fit, tests),
    fmg_reference_pvalues(fit, tests),
    tolerance = 1e-7,
    ignore_attr = TRUE
  )
}

fmg_expect_fitmeasures_semtests_parity <- function(
    fit,
    tests = fmg_single_model_tests()) {
  testthat::expect_equal(
    fmg_fitmeasures_pvalues(fit, tests),
    fmg_reference_pvalues(fit, tests),
    tolerance = 1e-7,
    ignore_attr = TRUE
  )
}

fmg_expect_nested_semtests_parity <- function(restricted, unrestricted,
                                              tests = fmg_nested_model_tests(),
                                              semtests_method = "2000",
                                              lrt_method = "satorra.2000") {
  testthat::expect_equal(
    fmg_lavtest_lrt_pvalues(
      restricted,
      unrestricted,
      tests,
      method = lrt_method
    ),
    fmg_reference_nested_pvalues(
      restricted,
      unrestricted,
      tests,
      method = semtests_method
    ),
    tolerance = 1e-7,
    ignore_attr = TRUE
  )
}
