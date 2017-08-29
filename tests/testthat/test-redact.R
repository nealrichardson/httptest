context("Redaction")

with_mock_API({
    d <- tempfile()
    capture_requests(simplify=FALSE, path=d, {
        a <- GET("api/", add_headers(`Authorization`="Bearer token"))
    })
    test_that("The response has the real request header", {
        expect_equal(a$request$headers[["Authorization"]], "Bearer token")
    })
    test_that("But the mock file does not", {
        expect_false(any(grepl("Bearer token", readLines(file.path(d, "api.R")))))
    })
    test_that("And when loading that .R mock, the redacted value doesn't appear", {
        .mockPaths(d)
        on.exit(options(httptest.mock.paths=NULL))
        b <- GET("api/", add_headers(`Authorization`="Bearer token"))
        expect_equal(b$request$headers[["Authorization"]], "REDACTED")

    })
})
