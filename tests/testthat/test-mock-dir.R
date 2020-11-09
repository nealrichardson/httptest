public({
    test_that("with_mock_dir works when the directory with mock files exists", {
        withr::local_envvar(list("TESTING_MOCK_DIR" = TRUE))

        temporary_dir <- withr::local_tempdir()
        file.copy(testthat::test_path("httpbin.org"), temporary_dir, recursive = TRUE)

        withr::local_dir(temporary_dir)

        current_mock_paths <- .mockPaths()

        with_mock_dir(temporary_dir, {
            httptest::expect_no_request(GET("http://httpbin.org/status/204"))
            resp <- GET("http://httpbin.org/status/204")
            expect_equal(headers(resp)$date, "Sat, 24 Feb 2018 00:22:11 GMT")
            expect_equal(.mockPaths(), "httpbin.org")
        })

        expect_true(all.equal(current_mock_paths, .mockPaths()))

    })
})

public({
    test_that("with_mock_dir creates mock files directory", {
        skip_if_disconnected()

        withr::local_envvar(list("TESTING_MOCK_DIR" = TRUE))

        temporary_dir <- withr::local_tempdir()

        withr::local_dir(temporary_dir)

        current_mock_paths <- .mockPaths()

        with_mock_dir("httpbin.org", {
            resp <- GET("http://httpbin.org/status/204")
            expect_false(headers(resp)$date == "Sat, 24 Feb 2018 00:22:11 GMT")
            httptest::expect_no_request(GET("http://httpbin.org/status/204"))
            expect_equal(.mockPaths(), "httpbin.org")
        })

        expect_true(all.equal(current_mock_paths, .mockPaths()))
    })
})
