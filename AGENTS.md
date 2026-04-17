# AGENTS.md

This file gives coding agents the current operating context for this lavaan
checkout. More detailed project notes live in `docs/agents/`.

## Current Project

lavaan is an R package for latent variable analysis: CFA, SEM, path analysis,
growth models, and related model families. The active local branch is
`semTests`.

The local goal is to integrate selected semTests p-value methods into lavaan
core while keeping the implementation close to existing lavaan infrastructure.
The source reference is the untracked local `semTests/` directory.

## Read First

- `docs/agents/rules.md` for working rules and package constraints.
- `docs/agents/roadmap.md` for implementation tasks and intended order.
- `docs/agents/progress.md` for current status and known gaps.
- `inst/understanding_lavaan_internals.R` for lavaan architecture details.

## Important Files

- `R/lav_test.R`: `lavTest()`, `lav_model_test()`, and test-name validation.
- `R/lav_test_fmg.R`: current FMG helper implementation draft.
- `R/lav_test_satorra_bentler.R`: main pattern for scaled-test integration.
- `R/lav_test_diff.R`: nested-model difference-test infrastructure.
- `R/lav_samplestats_gamma.R`: Gamma matrix computation.
- `R/lav_fit_measures.R`: fit index and p-value extraction path.
- `semTests/R/pvalues.R`, `semTests/R/tests.R`, `semTests/R/gamma.R`: reference
  implementation.

## Build And Check

Use the narrowest check that exercises the changed surface, then broaden before
handing off substantial changes.

```sh
R CMD build .
R CMD check .
Rscript -e "rcmdcheck::rcmdcheck()"
```

This checkout currently has no tracked `tests/` directory in the lavaan package.
If adding tests, follow the repository's existing package style and avoid
vendoring semTests test artifacts directly unless that is an explicit task.

## Current Caveats

- The worktree has local untracked and modified files. Do not overwrite them
  without checking the diff first.
- `semTests/` is a nested source reference with its own `.git` directory. Treat
  it as reference material, not as lavaan package content.
- `.codex` is currently an empty untracked file. Leave it alone unless the user
  asks to replace it with a directory or config.
- Agent coordination files are excluded from R package builds via
  `.Rbuildignore`.
