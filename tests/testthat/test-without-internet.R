context("without_internet")

public({
    test_that("Outside of without_internet, requests work", {
        skip_if_disconnected()
        expect_error(GET("http://httpbin.org/get"), NA)
    })
    test_that("without_internet throws errors on GET", {
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
            b2 <- "http://httpbin.org/post"
            expect_POST(POST(b2, body = list(x = "A simple text string")),
                'http://httpbin.org/post',
                'list(x = "A simple text string")')
        })

        test_that("max.print option", {
            options(httptest.max.print=3)
            on.exit(options(httptest.max.print=NULL))
            expect_PUT(PUT("http://httpbin.org/get", body='{"test":true}'),
                "http://httpbin.org/get",
                '{"t')
            ## Just to be explicit since the expectations do partial matching
            expect_failure(
                expect_PUT(PUT("http://httpbin.org/get", body='{"test":true}'),
                    "http://httpbin.org/get",
                    '{"test":true}')
            )
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
