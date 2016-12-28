context("Fake HTTP")

public({
    with_fake_HTTP({
        test_that("fakeGET", {
            expect_message(g <- GET("http://httpbin.org/get"),
                "GET http://httpbin.org/get")
            expect_null(content(g))
        })
        test_that("fakeGET with query", {
            expect_message(g <- GET("http://httpbin.org/get", query=list(a=1)),
                "GET http://httpbin.org/get")
            expect_equal(content(g), list(a=1))
        })
        test_that("fakePUT", {
            expect_message(p <- PUT("http://httpbin.org/get"),
                "PUT http://httpbin.org/get")
            expect_null(content(p))
        })
        test_that("fakePUT with body", {
            expect_message(p <- PUT("http://httpbin.org/get", body=list(b=2)),
                "PUT http://httpbin.org/get")
            expect_equal(content(p), list(b=2))
        })
        test_that("fakePATCH", {
            expect_message(p <- PATCH("http://httpbin.org/get"),
                "PATCH http://httpbin.org/get")
            expect_null(content(p))
        })
        test_that("fakePATCH with body", {
            expect_message(p <- PATCH("http://httpbin.org/get", body=list(b=2)),
                "PATCH http://httpbin.org/get")
            expect_equal(content(p), list(b=2))
        })
        test_that("fakePOST", {
            expect_message(p <- POST("http://httpbin.org/get"),
                "POST http://httpbin.org/get")
            expect_null(content(p))
        })
        test_that("fakePOST with body", {
            expect_message(p <- POST("http://httpbin.org/get", body=list(b=2)),
                "POST http://httpbin.org/get")
            expect_equal(content(p), list(b=2))
        })
        test_that("fakeDELETE", {
            expect_message(d <- DELETE("http://httpbin.org/get"),
                "DELETE http://httpbin.org/get")
            expect_null(content(d))
        })
    })
})
