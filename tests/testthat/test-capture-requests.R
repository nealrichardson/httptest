context("capture_requests")

test_that("We can record a series of requests", {
    skip_if_disconnected()
    d <- tempfile()
    capture_requests(path=d, {
        GET("http://httpbin.org/get")
        GET("http://httpbin.org")
        GET("http://httpbin.org/response-headers",
            query=list(`Content-Type`="application/json"))
        utils::download.file("http://httpbin.org/gzip", tempfile(), quiet=TRUE)
    })
    expect_true(setequal(dir(d, recursive=TRUE),
        c("httpbin.org.json",
          "httpbin.org/get.json",
          "httpbin.org/response-headers-ac4928.json",
          "httpbin.org/gzip")))
})

test_that("Recording requests even with the mock API", {
    with_mock_API({
        d2 <- tempfile()
        capture_requests(path=d2, {
            GET("http://example.com/get/")
            utils::download.file("api/object1.json", tempfile())
        })
        expect_true(setequal(dir(d2, recursive=TRUE),
            c("example.com/get.json", "api/object1.json")))
        expect_identical(readLines(file.path(d2, "example.com/get.json")),
            readLines("example.com/get.json"))
        expect_identical(readLines(file.path(d2, "api/object1.json")),
            readLines("api/object1.json"))
    })
})
