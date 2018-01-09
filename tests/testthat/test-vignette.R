context("start_vignette")

rp <- httr:::request_perform
g <- httr::GET

test_that("start/end_vignette with mocking", {
    start_vignette()
    expect_false(identical(rp, httr:::request_perform))
    expect_true(identical(g, httr::GET))
    end_vignette()
    expect_true(identical(rp, httr:::request_perform))
    expect_true(identical(g, httr::GET))
})

test_that("start/end_vignette with recording", {
    Sys.setenv(RECORD="true")
    on.exit(Sys.setenv(RECORD=""))
    start_vignette()
    expect_true(identical(rp, httr:::request_perform))
    expect_false(identical(g, httr::GET))
    end_vignette()
    expect_true(identical(rp, httr:::request_perform))
    expect_true(identical(g, httr::GET))
})

options(httptest.verbose=NULL)  ## Reset default

with_mock_API({
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
        expect_message(
            capture_while_mocking(simplify=FALSE, path=newmocks2, redact=NULL, {
                a <- GET("api/", add_headers(`Authorization`="Bearer token"))
            }),
            NA
        )
        expect_true(any(grepl("Bearer token", readLines(file.path(newmocks2, "api.R")))))
        skip_on_cran() ## They have a broken R-devel build that chokes on these
        with_mock_path(newmocks2, {
            b <- GET("api/", add_headers(`Authorization`="Bearer token"))
        })
        expect_equal(content(b), content(a))
    })
})
