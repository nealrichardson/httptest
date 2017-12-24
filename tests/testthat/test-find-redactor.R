context("Find package redactors")

expect_redactor <- function (expr) {
    expect_identical(names(formals(expr)), "response")
}

test_that("prepare_redactor: default", {
    expect_message(
        expect_identical(prepare_redactor(redact_auth), redact_auth),
        "Using default redactor"
    )
})

test_that("prepare_redactor: custom", {
    expect_message(
        expect_identical(prepare_redactor(redact_HTTP_auth), redact_HTTP_auth),
        "Using custom redactor"
    )
})

multiredact <- list(redact_HTTP_auth, redact_cookies)
test_that("prepare_redactor: list/multiple", {
    expect_message(
        expect_redactor(prepare_redactor(multiredact)),
        "Using 2 custom redactors"
    )
    expect_message(
        expect_identical(prepare_redactor(multiredact[1]), redact_HTTP_auth),
        "Using 1 custom redactor"
    )
})

test_that("prepare_redactor: named (from package)", {
    names(multiredact) <- c("mypkg", "yourpkg")
    expect_message(
        expect_redactor(prepare_redactor(multiredact)),
        paste0("Using redactors ", dQuote("mypkg"), ", ", dQuote("yourpkg"))
    )
    expect_message(
        expect_identical(prepare_redactor(multiredact[1]), redact_HTTP_auth),
        paste0("Using redactor ", dQuote("mypkg"))
    )
})

test_that("prepare_redactor: NULL for no redacting", {
    expect_message(
        expect_identical(prepare_redactor(NULL), force),
        NA
    )
})

test_that("prepare_redactor: garbage", {
    expect_error(prepare_redactor("foo"),
        "Redactor must be a function or list of functions"
    )
})
