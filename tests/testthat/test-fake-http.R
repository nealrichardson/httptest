context("Fake HTTP")

public({
    with_fake_HTTP({
        test_that("fakeGET", {
            expect_message(g <- GET("http://httpbin.org/get"),
                "GET http://httpbin.org/get")
            expect_null(content(g))
            expect_identical(g$url, "http://httpbin.org/get")
        })
        test_that("expect_GET with/without omitted url", {
            expect_GET(GET("http://httpbin.org/get"),
                "http://httpbin.org/get")
            expect_GET(GET("http://httpbin.org/get"))
        })
        test_that("fakeGET with query", {
            expect_GET(g <- GET("http://httpbin.org/get", query=list(a=1)),
                "http://httpbin.org/get?a=1")
            expect_null(content(g))
            expect_identical(g$url, "http://httpbin.org/get?a=1")
        })
        test_that("fakePUT", {
            expect_PUT(p <- PUT("http://httpbin.org/get"),
                "http://httpbin.org/get")
            expect_null(content(p))
            expect_identical(p$url, "http://httpbin.org/get")
        })
        test_that("fakePUT with body", {
            expect_PUT(p <- PUT("http://httpbin.org/get", body='{"b":2}'),
                "http://httpbin.org/get")
            expect_equal(content(p), list(b=2))
            expect_identical(p$url, "http://httpbin.org/get")
        })
        test_that("expect_PUT with/without omitted url", {
            expect_PUT(PUT("http://httpbin.org/get"),
                "http://httpbin.org/get")
            expect_PUT(PUT("http://httpbin.org/get"))
        })
        test_that("fakePATCH", {
            expect_PATCH(p <- PATCH("http://httpbin.org/get"),
                "http://httpbin.org/get")
            expect_null(content(p))
            expect_identical(p$url, "http://httpbin.org/get")
        })
        test_that("fakePATCH with body", {
            expect_PATCH(p <- PATCH("http://httpbin.org/get", body='{"b":2}'),
                "http://httpbin.org/get")
            expect_equal(content(p), list(b=2))
            expect_identical(p$url, "http://httpbin.org/get")
        })
        test_that("expect_PATCH with/without omitted url", {
            expect_PATCH(PATCH("http://httpbin.org/get"),
                "http://httpbin.org/get")
            expect_PATCH(PATCH("http://httpbin.org/get"))
        })
        test_that("fakePOST", {
            expect_POST(p <- POST("http://httpbin.org/get"),
                "http://httpbin.org/get")
            expect_null(content(p))
            expect_identical(p$url, "http://httpbin.org/get")
        })
        test_that("fakePOST with body", {
            expect_POST(p <- POST("http://httpbin.org/get", body='{"b":2}'),
                "http://httpbin.org/get")
            expect_equal(content(p), list(b=2))
            expect_identical(p$url, "http://httpbin.org/get")
        })
        test_that("expect_POST with/without omitted url", {
            expect_POST(POST("http://httpbin.org/get"),
                "http://httpbin.org/get")
            expect_POST(POST("http://httpbin.org/get"))
        })
        test_that("fakeDELETE", {
            expect_DELETE(d <- DELETE("http://httpbin.org/get"),
                "http://httpbin.org/get")
            expect_null(content(d))
            expect_identical(d$url, "http://httpbin.org/get")
        })
        test_that("expect_DELETE with/without omitted url", {
            expect_DELETE(DELETE("http://httpbin.org/get"),
                "http://httpbin.org/get")
            expect_DELETE(DELETE("http://httpbin.org/get"))
        })
        test_that("fakeDownload", {
            f <- tempfile()
            expect_message(dl <- download.file("http://httpbin.org/get", f),
                "DOWNLOAD http://httpbin.org/get")
            expect_identical(readLines(f), "http://httpbin.org/get")
            expect_equal(dl, 0)
        })
    })
})
