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

capture_requests({
    skip_if_disconnected()
    cooks <- GET("http://httpbin.org/cookies", config(cookie="token=12345"))
    print(str(cooks))
    print(content(cooks))
    c2 <- GET("http://httpbin.org/cookies/set", query=list(token=12345))
    print(str(c2))
    print(content(c2))
    test_that("redact_cookies", {

    })

    test_that("redact_HTTP_auth", {
        # GET("http://httpbin.org/basic-auth/user/passwd", authenticate("user", "passwd"))
    })
})
