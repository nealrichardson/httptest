context("Find package redactors")

expect_redactor <- function (expr) {
    expect_identical(names(formals(expr)), "response")
}

test_that("prepare_redactor: function", {
    expect_identical(prepare_redactor(redact_http_auth), redact_http_auth)
})

multiredact <- list(redact_http_auth, redact_cookies)
test_that("prepare_redactor: list/multiple", {
    expect_redactor(prepare_redactor(multiredact))
    expect_identical(prepare_redactor(multiredact[1]), redact_http_auth)
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
    options(httptest.redactor=NULL)
    expect_identical(get_current_redactor(), redact_auth)
    options(httptest.redactor.packages="NOTAPACKAGE")
    expect_identical(get_current_redactor(), redact_auth)
})

with_mock_api({
    test_that("Reading redactors from within a package (and install that package)", {
        newmocks <- tempfile()
        expect_message(
            capture_while_mocking(path=newmocks, {
                ## Install the "testpkg" to a temp lib.loc _after_ we've already started recording
                lib <- tempfile()
                dir.create(lib)
                Rcmd(c("INSTALL", "testpkg", paste0("--library=", shQuote(lib))),
                    stdout=NULL, stderr=NULL)
                library(testpkg, lib.loc=lib)
                expect_true("testpkg" %in% names(sessionInfo()$otherPkgs))

                r <- GET("http://example.com/get")
            }),
            paste0("Using redact.R from ", dQuote("testpkg"))
        )
        with_mock_path(newmocks, {
            r2 <- GET("http://example.com/get")
        })
        ## The resulting mock content is what we injected into it from testpkg
        expect_identical(content(r2), list(fake=TRUE))
    })

    test_that("Request preprocessing via package inst/httptest/request.R", {
        ## That function prunes a leading http://pythong.org/ from URLs
        expect_identical(content(GET("http://pythong.org/api/object1/")),
            content(GET("api/object1/")))
    })

    test_that("redact=NULL to override default (and loaded packages)", {
        expect_true("testpkg" %in% names(sessionInfo()$otherPkgs))
        ## Great, but let's kill it when we're done
        on.exit(detach(package:testpkg))
        newmocks2 <- tempfile()
        expect_warning(
            capture_while_mocking(simplify=FALSE, path=newmocks2, redact=NULL, {
                a <- GET("api/", add_headers(`Authorization`="Bearer token"))
            }),
            "The 'redact' argument to start_capturing() is deprecated. Use 'set_redactor()' instead.", fixed=TRUE
        )
        expect_true(any(grepl("Bearer token", readLines(file.path(newmocks2, "api.R")))))
        with_mock_path(newmocks2, {
            b <- GET("api/", add_headers(`Authorization`="Bearer token"))
        })
        expect_equal(content(b), content(a))
    })
})
