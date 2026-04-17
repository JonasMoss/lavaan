# FMG (Foldnes, Moss, Gronneberg 2024) test statistics
# Improved goodness-of-fit tests using eigenvalue methods
#
# References:
# - Foldnes, N., Moss, J., & Gronneberg, S. (2024). Improved goodness of fit
#   procedures for structural equation models. Structural Equation Modeling.
# - Foldnes, N., & Gronneberg, S. (2018). Approximating Test Statistics Using
#   Eigenvalue Block Averaging. Structural Equation Modeling.
# - Du, H., & Bentler, P. M. (2022). 40-Year Old Unbiased Distribution Free
#   Estimator Reliably Improves SEM Statistics for Nonnormal Data.
# - Wu, H., & Lin, J. (2016). A Scaled F Distribution as an Approximation to
#   the Distribution of Test Statistics in Covariance Structure Analysis.

# =====================================================
# Parser (ported from semTests split_input)
# =====================================================

#' Check if test string is an FMG test
#' @param test Character string specifying the test
#' @return Logical indicating if this is an FMG test
#' @keywords internal
lav_test_fmg_is_fmg <- function(test) {
  test <- tolower(test)
  patterns <- c("^peba", "^eba[0-9]?$", "^eba[0-9]+_", "^pols", "^pall", "^all$",
                "^all_", "^sb_", "^ss_", "^sf_", "^std_")
  any(vapply(patterns, function(p) grepl(p, test), logical(1)))
}

#' Parse FMG test string into components
#'
#' Format: {method}{param}_{ug?}_{chisq?}
#' Examples: peba4_ug_rls, eba2, pols2_ml, sb_ug
#'
#' @param string Character string specifying the test
#' @return List with method, param, unbiased, chisq
#' @keywords internal
lav_test_fmg_parse <- function(string) {
  string <- tolower(string)
  splitted <- strsplit(string, "_")[[1]]

  # Defaults
  method <- NULL
  param <- 2L  # default for j (eba/peba) or gamma (pols)
  unbiased <- FALSE
  chisq <- "rls"

  type <- splitted[1]

  # Parse unbiased and chisq from suffix parts
  if (length(splitted) == 3L) {
    unbiased <- (splitted[2] == "ug")
    chisq <- splitted[3]
  } else if (length(splitted) == 2L) {
    if (splitted[2] %in% c("rls", "ml")) {
      chisq <- splitted[2]
    } else if (splitted[2] == "ug") {
      unbiased <- TRUE
    }
  }

  # Parse method and parameter
  if (startsWith(type, "peba")) {
    method <- "peba"
    param_str <- substring(type, 5)
    if (nchar(param_str) > 0L) param <- as.integer(param_str)
  } else if (startsWith(type, "eba")) {
    method <- "eba"
    param_str <- substring(type, 4)
    if (nchar(param_str) > 0L) param <- as.integer(param_str)
  } else if (startsWith(type, "pols")) {
    method <- "pols"
    param_str <- substring(type, 5)
    if (nchar(param_str) > 0L) param <- as.numeric(param_str)
  } else if (type == "pall") {
    method <- "pall"
  } else if (type == "all") {
    method <- "all"
  } else if (type %in% c("sb", "ss", "sf", "std")) {
    method <- type
  } else {
    lav_msg_stop(gettextf("invalid FMG test type: %s", type))
  }

  list(method = method, param = param, unbiased = unbiased, chisq = chisq)
}

# =====================================================
# Main entry point
# =====================================================

#' Compute FMG test statistics
#'
#' @param lavobject A lavaan object
#' @param lavsamplestats Sample statistics (extracted from lavobject if NULL)
#' @param lavmodel Model object (extracted from lavobject if NULL)
#' @param lavdata Data object (extracted from lavobject if NULL)
#' @param lavoptions Options (extracted from lavobject if NULL)
#' @param TEST.unscaled Unscaled test from lavobject@test[[1]]
#' @param test Character string specifying the test (e.g., "peba4_ug_rls")
#' @return List with test results including stat, df, pvalue
#' @keywords internal
lav_test_fmg <- function(lavobject = NULL,
                         lavsamplestats = NULL,
                         lavmodel = NULL,
                         lavimplied = NULL,
                         lavdata = NULL,
                         lavoptions = NULL,
                         TEST.unscaled = NULL,
                         TEST.chisq = NULL,
                         E.inv = NULL,
                         Delta = NULL,
                         WLS.V = NULL,
                         Gamma = NULL,
                         test = "peba4") {

  # Extract from lavobject if provided
  if (!is.null(lavobject)) {
    lavsamplestats <- lavobject@SampleStats
    lavmodel <- lavobject@Model
    lavoptions <- lavobject@Options
    lavdata <- lavobject@Data
    if (is.null(TEST.unscaled)) {
      TEST.unscaled <- lavobject@test[[1]]
    }
  }

  # Parse test string
  parsed <- lav_test_fmg_parse(test)

  if (is.null(TEST.chisq)) {
    TEST.chisq <- TEST.unscaled
    if (parsed$chisq == "rls") {
      if (is.null(lavobject)) {
        return(NULL)
      }
      TEST.chisq <- lavTest(lavobject,
                            test = "browne.residual.nt.model")
    }
  }
  chisq_stat <- TEST.chisq$stat

  # Get df
  df <- TEST.unscaled$df

  # Handle df == 0 case
 if (df == 0L || df < 0L) {
    return(list(
      test = test,
      stat = chisq_stat,
      stat.group = TEST.chisq$stat.group,
      df = df,
      pvalue = as.numeric(NA),
      refdistr = "fmg",
      method = parsed$method,
      param = parsed$param,
      unbiased = parsed$unbiased,
      chisq.type = parsed$chisq
    ))
  }

  # Get UGamma matrix (with unbiased option)
  UGamma <- lav_test_fmg_ugamma(
    lavobject = lavobject,
    lavsamplestats = lavsamplestats,
    lavmodel = lavmodel,
    lavimplied = lavimplied,
    lavdata = lavdata,
    lavoptions = lavoptions,
    TEST.unscaled = TEST.unscaled,
    E.inv = E.inv,
    Delta = Delta,
    WLS.V = WLS.V,
    Gamma = Gamma,
    unbiased = parsed$unbiased
  )

  if (is.null(UGamma)) {
    return(list(
      test = test,
      stat = chisq_stat,
      stat.group = TEST.chisq$stat.group,
      df = df,
      pvalue = as.numeric(NA),
      refdistr = "fmg",
      method = parsed$method,
      param = parsed$param,
      unbiased = parsed$unbiased,
      chisq.type = parsed$chisq
    ))
  }

  # Compute eigenvalues (first df eigenvalues)
  lambdas <- Re(eigen(UGamma, only.values = TRUE)$values)[seq_len(df)]

  # Compute p-value based on method
  pvalue <- switch(parsed$method,
    "peba" = lav_test_fmg_peba(chisq_stat, lambdas, j = parsed$param),
    "eba"  = lav_test_fmg_eba(chisq_stat, lambdas, j = parsed$param),
    "pols" = lav_test_fmg_pols(chisq_stat, lambdas, gamma = parsed$param),
    "pall" = lav_test_fmg_pall(chisq_stat, lambdas),
    "all"  = lav_test_fmg_all(chisq_stat, lambdas),
    "sb"   = lav_test_fmg_sb(chisq_stat, lambdas),
    "ss"   = lav_test_fmg_ss(chisq_stat, lambdas, df),
    "sf"   = lav_test_fmg_scaled_f(chisq_stat, lambdas),
    "std"  = 1 - stats::pchisq(chisq_stat, df),
    lav_test_fmg_peba(chisq_stat, lambdas, j = 4L)  # default
  )

  # Ensure p-value is in valid range
  pvalue <- max(0, min(1, pvalue))

  # Return TEST structure
  list(
    test = test,
    stat = chisq_stat,
    stat.group = TEST.chisq$stat.group,
    df = df,
    pvalue = pvalue,
    refdistr = "fmg",
    method = parsed$method,
    param = parsed$param,
    unbiased = parsed$unbiased,
    chisq.type = parsed$chisq,
    UGamma.eigenvalues = lambdas
  )
}

# =====================================================
# UGamma computation
# =====================================================

#' Get UGamma matrix with optional unbiased gamma
#'
#' @param lavobject A lavaan object
#' @param unbiased Logical: use Du & Bentler (2022) unbiased gamma?
#' @return UGamma matrix
#' @keywords internal
lav_test_fmg_ugamma <- function(lavobject = NULL,
                                lavsamplestats = NULL,
                                lavmodel = NULL,
                                lavimplied = NULL,
                                lavdata = NULL,
                                lavoptions = NULL,
                                TEST.unscaled = NULL,
                                E.inv = NULL,
                                Delta = NULL,
                                WLS.V = NULL,
                                Gamma = NULL,
                                unbiased = FALSE) {

  if (!is.null(lavobject)) {
    lavsamplestats <- lavobject@SampleStats
    lavmodel <- lavobject@Model
    lavimplied <- lavobject@implied
    lavoptions <- lavobject@Options
    lavdata <- lavobject@Data
    if (is.null(TEST.unscaled)) {
      TEST.unscaled <- lavobject@test[[1]]
    }
  }

  ngroups <- lavdata@ngroups

  if (unbiased) {
    # Recompute Gamma with unbiased = TRUE
    Gamma <- vector("list", ngroups)
    for (g in seq_len(ngroups)) {
      Gamma[[g]] <- lav_samplestats_Gamma(
        Y = lavdata@X[[g]],
        meanstructure = lavoptions$meanstructure,
        unbiased = TRUE
      )
    }
  } else {
    if (is.null(Gamma)) {
      if (!is.null(lavobject)) {
        Gamma <- lavTech(lavobject, "Gamma")
      } else {
        Gamma <- lavsamplestats@NACOV
      }
    }
    if (!is.list(Gamma)) {
      Gamma <- list(Gamma)
    }
  }

  # Get U matrix and UGamma using existing infrastructure
  out <- lav_test_satorra_bentler(
    lavobject = lavobject,
    lavsamplestats = lavsamplestats,
    lavmodel = lavmodel,
    lavimplied = lavimplied,
    lavdata = lavdata,
    lavoptions = lavoptions,
    TEST.unscaled = TEST.unscaled,
    E.inv = E.inv,
    Delta = Delta,
    WLS.V = WLS.V,
    Gamma = Gamma,
    method = "original",
    return.ugamma = TRUE,
    return.u = TRUE
  )

  if (is.null(out)) {
    return(NULL)
  }

  # If unbiased, recompute UGamma with new Gamma
  if (unbiased) {
    U <- out$UfromUGamma
    if (is.null(U)) {
      return(NULL)
    }

    # Rescale gamma by group weights
    fg <- unlist(lavsamplestats@nobs) / lavsamplestats@ntotal
    Gamma_scaled <- vector("list", length(Gamma))
    for (g in seq_along(Gamma)) {
      Gamma_scaled[[g]] <- Gamma[[g]] / fg[g]
    }
    Gamma_all <- lav_matrix_bdiag(Gamma_scaled)
    UGamma <- U %*% Gamma_all
  } else {
    UGamma <- out$UGamma
  }

  UGamma
}

# =====================================================
# P-value methods
# =====================================================

#' Penalized EBA p-value (Foldnes et al. 2024)
#'
#' @param chisq Chi-square statistic
#' @param lambdas Eigenvalues of UGamma
#' @param j Number of blocks
#' @return p-value
#' @keywords internal
lav_test_fmg_peba <- function(chisq, lambdas, j = 4L) {
  m <- length(lambdas)
  if (m == 0L) return(as.numeric(NA))

  k <- ceiling(m / j)
  eig <- c(lambdas, rep(NA_real_, k * j - m))
  dim(eig) <- c(k, j)
  eig_means <- colMeans(eig, na.rm = TRUE)
  eig_mean <- mean(lambdas)
  repeated <- rep(eig_means, each = k)[seq_len(m)]
  penalized <- (repeated + eig_mean) / 2

  CompQuadForm::imhof(chisq, penalized)$Qq
}

#' EBA p-value (Foldnes & Gronneberg 2018)
#'
#' @param chisq Chi-square statistic
#' @param lambdas Eigenvalues of UGamma
#' @param j Number of blocks
#' @return p-value
#' @keywords internal
lav_test_fmg_eba <- function(chisq, lambdas, j = 4L) {
  m <- length(lambdas)
  if (m == 0L) return(as.numeric(NA))

  k <- ceiling(m / j)
  eig <- c(lambdas, rep(NA_real_, k * j - m))
  dim(eig) <- c(k, j)
  eig_means <- colMeans(eig, na.rm = TRUE)
  repeated <- rep(eig_means, each = k)[seq_len(m)]

  CompQuadForm::imhof(chisq, repeated)$Qq
}

#' Penalized OLS p-value (Foldnes et al. 2024)
#'
#' @param chisq Chi-square statistic
#' @param lambdas Eigenvalues of UGamma
#' @param gamma Penalization parameter
#' @return p-value
#' @keywords internal
lav_test_fmg_pols <- function(chisq, lambdas, gamma = 2) {
  m <- length(lambdas)
  if (m == 0L) return(as.numeric(NA))

  if (m == 1L) {
    lambda_hat <- lambdas
  } else {
    x <- seq_along(lambdas)
    beta1_hat <- 1 / gamma * stats::cov(x, lambdas) / stats::var(x)
    beta0_hat <- mean(lambdas) - beta1_hat * mean(x)
    lambda_hat <- pmax(beta0_hat + beta1_hat * x, 0)
  }

  CompQuadForm::imhof(chisq, lambda_hat)$Qq
}

#' Penalized all eigenvalues (for nested models)
#'
#' @param chisq Chi-square statistic
#' @param lambdas Eigenvalues of UGamma
#' @return p-value
#' @keywords internal
lav_test_fmg_pall <- function(chisq, lambdas) {
  if (length(lambdas) == 0L) return(as.numeric(NA))

  penalized <- lambdas / 2 + mean(lambdas) / 2
  CompQuadForm::imhof(chisq, penalized)$Qq
}

#' All eigenvalues exact p-value
#'
#' @param chisq Chi-square statistic
#' @param lambdas Eigenvalues of UGamma
#' @return p-value
#' @keywords internal
lav_test_fmg_all <- function(chisq, lambdas) {
  if (length(lambdas) == 0L) return(as.numeric(NA))

  CompQuadForm::imhof(chisq, lambdas)$Qq
}

#' Satorra-Bentler via eigenvalues
#'
#' @param chisq Chi-square statistic
#' @param lambdas Eigenvalues of UGamma
#' @return p-value
#' @keywords internal
lav_test_fmg_sb <- function(chisq, lambdas) {
  m <- length(lambdas)
  if (m == 0L) return(as.numeric(NA))

  1 - stats::pchisq(chisq * m / sum(lambdas), df = m)
}

#' Scaled and shifted p-value
#'
#' @param chisq Chi-square statistic
#' @param lambdas Eigenvalues of UGamma
#' @param df Degrees of freedom
#' @return p-value
#' @keywords internal
lav_test_fmg_ss <- function(chisq, lambdas, df) {
  if (length(lambdas) == 0L || df == 0L) return(as.numeric(NA))

  tr_ug <- sum(lambdas)
  tr_ug2 <- sum(lambdas^2)

  if (tr_ug2 < .Machine$double.eps) return(as.numeric(NA))

  a <- sqrt(df / tr_ug2)
  b <- df - sqrt(df * tr_ug^2 / tr_ug2)
  t3 <- chisq * a + b

  1 - stats::pchisq(t3, df)
}

#' Scaled F p-value (Wu & Lin 2016)
#'
#' @param chisq Chi-square statistic
#' @param lambdas Eigenvalues of UGamma
#' @return p-value
#' @keywords internal
lav_test_fmg_scaled_f <- function(chisq, lambdas) {
  if (length(lambdas) == 0L) return(as.numeric(NA))

  s1 <- sum(lambdas)
  s2 <- sum(lambdas^2)
  s3 <- sum(lambdas^3)
  denom <- 2 * s1 * s2^2 - s1^2 * s3 + 2 * s2 * s3

  if (denom > 0) {
    d1f3 <- s1 * (s1^2 * s2 - 2 * s2^2 + 4 * s1 * s3) / denom
    d2f3 <- (s1^2 * s2 + 2 * s2^2) / (s3 * s1 - s2^2) + 6
    if (d2f3 < 6) d2f3 <- Inf
    cf3 <- s1 * (s1^2 * s2 - 2 * s2^2 + 4 * s1 * s3) /
      (s1^2 * s2 - 4 * s2^2 + 6 * s1 * s3)
  } else {
    d1f3 <- Inf
    d2f3 <- s1^2 / s2 + 4
    cf3 <- s1 * (s1^2 + 2 * s2) / (s1^2 + 4 * s2)
  }

  1 - stats::pf(chisq / cf3, d1f3, d2f3)
}

# =====================================================
# Nested model implementation
# =====================================================

#' FMG test for nested model comparison
#'
#' @param m0 Restricted (null) model
#' @param m1 Unrestricted (alternative) model
#' @param test Test specification string (e.g., "pall_ug_ml")
#' @param method Either "2000" (Satorra) or "2001" (Satorra-Bentler)
#' @return List with test results
#' @keywords internal
lav_test_fmg_nested <- function(m0, m1, test = "pall", method = "2000") {

  # Ensure m0 has more df than m1
  if (m0@test[[1]]$df < m1@test[[1]]$df) {
    tmp <- m0
    m0 <- m1
    m1 <- tmp
  }

  # Parse test string
  parsed <- lav_test_fmg_parse(test)
  if (!parsed$method %in% c("pall", "all", "peba", "eba")) {
    lav_msg_stop(gettextf(
      "FMG nested tests support %1$s only; got %2$s.",
      lav_msg_view(c("pall", "all", "peba", "eba"), "or"),
      dQuote(parsed$method)
    ))
  }

  # Get df difference
  df0 <- m0@test[[1]]$df
  df1 <- m1@test[[1]]$df
  df <- df0 - df1

  if (df == 0L) {
    lav_msg_stop(gettext(
      "cannot test models with the same degrees of freedom"))
  }

  # Get chi-square difference
  if (parsed$chisq == "rls") {
    chisq0 <- lavTest(m0, "browne.residual.nt.model")$stat
    chisq1 <- lavTest(m1, "browne.residual.nt.model")$stat
  } else {
    chisq0 <- m0@test[[1]]$stat
    chisq1 <- m1@test[[1]]$stat
  }
  chisq_diff <- chisq0 - chisq1

  # Get UGamma for nested comparison
  UGamma <- lav_test_fmg_ugamma_nested(m0, m1,
                                        unbiased = parsed$unbiased,
                                        method = method)

  if (is.null(UGamma)) {
    return(list(
      test = test,
      stat = chisq_diff,
      df = df,
      pvalue = as.numeric(NA),
      method = method
    ))
  }

  # Compute first df eigenvalues
  lambdas <- Re(eigen(UGamma, only.values = TRUE)$values)[seq_len(df)]

  # Check for negative eigenvalues (fallback to method 2000)
  if (any(lambdas < 0) && method == "2001") {
    lav_msg_warn(gettext(
      "negative eigenvalues in first df eigenvalues of UGamma,
       falling back to method 2000"))
    UGamma <- lav_test_fmg_ugamma_nested(m0, m1,
                                          unbiased = parsed$unbiased,
                                          method = "2000")
    if (!is.null(UGamma)) {
      lambdas <- Re(eigen(UGamma, only.values = TRUE)$values)[seq_len(df)]
    }
  }

  # Compute p-value (pall is recommended for nested)
  pvalue <- switch(parsed$method,
    "pall" = lav_test_fmg_pall(chisq_diff, lambdas),
    "all"  = lav_test_fmg_all(chisq_diff, lambdas),
    "peba" = lav_test_fmg_peba(chisq_diff, lambdas, j = parsed$param),
    "eba"  = lav_test_fmg_eba(chisq_diff, lambdas, j = parsed$param)
  )

  list(
    test = test,
    stat = chisq_diff,
    df = df,
    pvalue = pvalue,
    method = method,
    UGamma.eigenvalues = lambdas
  )
}

#' Compute UGamma for nested models (Satorra 2000 method)
#'
#' @param m0 Restricted model
#' @param m1 Unrestricted model
#' @param unbiased Use unbiased gamma?
#' @param method "2000" or "2001"
#' @return UGamma matrix
#' @keywords internal
lav_test_fmg_ugamma_nested <- function(m0, m1, unbiased = FALSE,
                                        method = "2000") {

  lavdata <- m1@Data
  ngroups <- lavdata@ngroups

  # Get Gamma from m1 (with optional unbiased)
  if (unbiased) {
    Gamma <- vector("list", ngroups)
    for (g in seq_len(ngroups)) {
      Gamma[[g]] <- lav_samplestats_Gamma(
        Y = lavdata@X[[g]],
        meanstructure = m1@Options$meanstructure,
        unbiased = TRUE
      )
    }
  } else {
    Gamma <- lavTech(m1, "Gamma")
    if (is.null(Gamma)) {
      Gamma <- lavTech(m0, "Gamma")
    }
    if (is.null(Gamma)) {
      lav_msg_stop(gettext(
        "could not calculate the gamma matrix. Use estimator = 'MLM' or
         test = 'satorra.bentler' when fitting your lavaan model."))
    }
    if (!is.list(Gamma)) Gamma <- list(Gamma)
  }

  if (method == "2001") {
    # Simple: (U0 - U1) %*% Gamma
    U0 <- lavInspect(m0, "U")
    U1 <- lavInspect(m1, "U")

    # Scale gamma by group weights
    fg <- unlist(m1@SampleStats@nobs) / m1@SampleStats@ntotal
    Gamma_scaled <- vector("list", length(Gamma))
    for (g in seq_along(Gamma)) {
      Gamma_scaled[[g]] <- Gamma[[g]] / fg[g]
    }
    Gamma_all <- lav_matrix_bdiag(Gamma_scaled)
    UGamma <- (U0 - U1) %*% Gamma_all

  } else {
    # Satorra 2000 method (more robust)
    WLS.V <- lavTech(m1, "WLS.V")
    PI <- lav_model_delta(m1@Model)
    P.inv <- lavTech(m1, "inverted.information")

    if (is.null(P.inv)) {
      return(NULL)
    }

    A <- lav_test_diff_A(m1, m0, method = "delta", reference = "H1")

    # Handle equality constraints
    if (m1@Model@eq.constraints) {
      A <- A %*% t(m1@Model@eq.constraints.K)
    } else if (m1@Model@ceq.simple.only) {
      A <- A %*% t(m1@Model@ceq.simple.K)
    }

    # Safety check: remove zero rows/columns
    APA <- A %*% P.inv %*% t(A)
    cSums <- colSums(APA)
    rSums <- rowSums(APA)
    empty.idx <- which(abs(cSums) < .Machine$double.eps^0.5 &
                       abs(rSums) < .Machine$double.eps^0.5)
    if (length(empty.idx) > 0L) {
      A <- A[-empty.idx, , drop = FALSE]
    }

    if (nrow(A) == 0L) {
      return(NULL)
    }

    # PAAPAAP projection
    PAAPAAP <- P.inv %*% t(A) %*% MASS::ginv(A %*% P.inv %*% t(A)) %*%
               A %*% P.inv

    # Build global matrices
    fg <- unlist(m1@SampleStats@nobs) / m1@SampleStats@ntotal
    Gamma_f <- vector("list", length(Gamma))
    for (g in seq_along(Gamma)) {
      Gamma_f[[g]] <- Gamma[[g]] / fg[g]
    }
    Gamma_all <- lav_matrix_bdiag(Gamma_f)

    V_f <- WLS.V
    for (g in seq_along(WLS.V)) {
      V_f[[g]] <- fg[g] * WLS.V[[g]]
    }
    V_all <- lav_matrix_bdiag(V_f)

    PI_all <- do.call(rbind, PI)

    # U_global (eq. 22 in Satorra 2000)
    U_all <- V_all %*% PI_all %*% PAAPAAP %*% t(PI_all) %*% V_all
    UGamma <- U_all %*% Gamma_all
  }

  UGamma
}
