context("expect_header")

public({
    with_fake_http({
        test_that("expect_header with fake HTTP", {
            expect_GET(expect_success(expect_header(GET("http://httpbin.org/",
                config=add_headers(Accept="image/jpeg")),
                "Accept: image/jpeg")))
            expect_GET(expect_failure(expect_header(GET("http://httpbin.org/",
                config=add_headers(Accept="image/png")),
                "Accept: image/jpeg")))
            expect_POST(expect_success(expect_header(POST("http://httpbin.org/",
                config=add_headers(Accept="image/jpeg")),
                "Accept: image/jpeg")))
            expect_POST(expect_failure(expect_header(POST("http://httpbin.org/",
                config=add_headers(Accept="image/png")),
                "Accept: image/jpeg")))
        })
    })

    with_mock_api({
        test_that("expect_header with mock API", {
            expect_success(expect_header(GET("api/object1/",
                config=add_headers(Accept="image/jpeg")),
                "Accept: image/jpeg"))
            expect_failure(expect_header(GET("api/object1/",
                config=add_headers(Accept="image/png")),
                "Accept: image/jpeg"))
            expect_POST(expect_success(expect_header(POST("http://httpbin.org/",
                config=add_headers(Accept="image/jpeg")),
                "Accept: image/jpeg")))
            expect_failure(expect_header(expect_POST(POST("http://httpbin.org/",
                config=add_headers(Accept="image/png")), silent=TRUE),
                "Accept: image/jpeg"))
        })
        test_that("expect_header ignore.case", {
            expect_success(expect_header(GET("api/object1/",
                config=add_headers(Accept="image/jpeg")),
                "accept: image/jpeg"))
            expect_failure(expect_header(GET("api/object1/",
                config=add_headers(Accept="image/jpeg")),
                "accept: image/jpeg",
                ignore.case=FALSE))
        })
    })

    without_internet({
        test_that("expect_header without_internet", {
            expect_GET(expect_success(expect_header(GET("http://httpbin.org/",
                config=add_headers(Accept="image/jpeg")),
                "Accept: image/jpeg")))
            expect_GET(expect_failure(expect_header(GET("http://httpbin.org/",
                config=add_headers(Accept="image/png")),
                "Accept: image/jpeg")))
        })
    })

    test_that("expect_header works with actual network too", {
        skip_if_disconnected()
        expect_success(expect_header(GET("http://httpbin.org/get",
            config=add_headers(Accept="image/jpeg")),
            "Accept: image/jpeg"))
        expect_failure(expect_header(GET("http://httpbin.org/get",
            config=add_headers(Accept="image/png")),
            "Accept: image/jpeg"))
    })
})
