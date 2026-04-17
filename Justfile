set shell := ["bash", "-eu", "-c"]

default: test

test:
    Rscript -e 'testthat::test_local(".", reporter = "summary", stop_on_failure = TRUE)'

test-file file:
    Rscript -e 'pkgload::load_all(".", export_all = FALSE); testthat::test_file("{{file}}", reporter = "summary")'

build:
    R CMD build .

check:
    R CMD build .
    R CMD check lavaan_*.tar.gz

status:
    git status --short --branch
