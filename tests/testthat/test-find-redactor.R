context("Find package redactors")

expect_redactor <- function (expr) {
    expect_identical(names(formals(expr)), "response")
}

test_that("prepare_redactor: function", {
    expect_identical(prepare_redactor(redact_HTTP_auth), redact_HTTP_auth)
})

multiredact <- list(redact_HTTP_auth, redact_cookies)
test_that("prepare_redactor: list/multiple", {
    expect_redactor(prepare_redactor(multiredact))
    expect_identical(prepare_redactor(multiredact[1]), redact_HTTP_auth)
})

test_that("prepare_redactor: NULL for no redacting", {
    expect_identical(prepare_redactor(NULL), force)
})

test_that("prepare_redactor: garbage", {
    expect_error(prepare_redactor("foo"),
        "Redactor must be a function or list of functions"
    )
})

test_that("get_current_redactor edge cases", {
    options(httptest.redactor.current=NULL)
    expect_identical(get_current_redactor(), redact_auth)
    options(httptest.redactor.packages="NOTAPACKAGE")
    expect_identical(get_current_redactor(), redact_auth)
})
