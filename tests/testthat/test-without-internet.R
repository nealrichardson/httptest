context("without_internet")

public({
    test_that("without_internet throws errors on GET", {
        expect_error(GET("http://httpbin.org/get"), NA)
        without_internet({
            expect_error(GET("http://httpbin.org/get"),
                "GET http://httpbin.org/get")
            expect_GET(GET("http://httpbin.org/get"),
                "http://httpbin.org/get")
        })
    })

    without_internet({
        test_that("without_internet throws error on other verbs", {
            expect_PUT(PUT("http://httpbin.org/get"),
                "http://httpbin.org/get")
            expect_POST(POST("http://httpbin.org/get"),
                "http://httpbin.org/get")
            expect_PATCH(PATCH("http://httpbin.org/get"),
                "http://httpbin.org/get")
            expect_DELETE(DELETE("http://httpbin.org/get"),
                "http://httpbin.org/get")
        })

        test_that("without_internet includes request body in message", {
            expect_PUT(PUT("http://httpbin.org/get", body='{"test":true}'),
                "http://httpbin.org/get",
                '{"test":true}')
            expect_POST(POST("http://httpbin.org/get", body='{"test":true}'),
                "http://httpbin.org/get",
                '{"test":true}')
            expect_PATCH(PATCH("http://httpbin.org/get", body='{"test":true}'),
                "http://httpbin.org/get",
                '{"test":true}')
        })

        test_that("without_internet respects query params", {
            expect_GET(GET("http://httpbin.org/get",
                query=list(test="a phrase", two=3)),
                "http://httpbin.org/get?test=a%20phrase&two=3")
        })

        test_that("expect_no_request", {
            expect_no_request(rnorm(5))
            expect_failure(expect_no_request(GET("http://httpbin.org/get")))
        })
    })
})
