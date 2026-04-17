# lavaan Context

## Package Shape

- `xxx_*.R` files hold public entry points such as `lavaan()`, `cfa()`, `sem()`,
  `growth()`, `lavaanList()`, EFA, SAM, and FSR helpers.
- `lav_*.R` files hold internal implementation modules.
- `00class.R` defines the main S4 classes.
- `00generic.R` defines generics such as `fitMeasures`, `lavInspect`, and
  `lavTech`.
- `zzz.R` and `zzz_OLDNAMES.R` handle startup and old-name compatibility.

## Main lavaan Workflow

The `lavaan()` workflow in `R/xxx_lavaan.R` proceeds broadly as:

1. Parse model syntax.
2. Set and check options.
3. Create the `lavData` object.
4. Build the parameter table.
5. Compute sample statistics.
6. Compute unrestricted H1 statistics.
7. Set parameter bounds.
8. Compute starting values.
9. Build the `lavModel`.
10. Build cache data.
11. Estimate parameters.
12. Compute implied statistics and log-likelihood.
13. Compute parameter covariance.
14. Compute test statistics.
15. Fit baseline model.
16. Handle EFA rotation.
17. Create the final `lavaan` S4 object.
18. Run post-fit checks.

## Relevant S4 Objects

- `lavaan`: final fitted object with slots such as `Options`, `ParTable`,
  `Data`, `SampleStats`, `Model`, `implied`, `vcov`, `test`, and `Cache`.
- `lavData`: data representation, grouping, missingness, and observed variables.
- `lavSampleStats`: sample moments, Gamma, and related statistics.
- `lavModel`: internal matrix representation.

## FMG Integration Reference

The prior `CLAUDE.md` notes identified the core target as Foldnes, Moss, and
Gronneberg-style improved goodness-of-fit methods. Keep that context, but treat
`docs/agents/roadmap.md` and `docs/agents/progress.md` as the up-to-date
working plan.
