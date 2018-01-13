context("Tracing")

public({
    test_that("safe_untrace makes mocking not error if not already traced", {
        expect_error(use_mock_api(), NA)
        expect_error(stop_mocking(), NA)
        expect_error(stop_mocking(), NA)
    })

    test_that("safe_untrace makes recording not error if not already traced", {
        expect_error(start_capturing(), NA)
        expect_error(stop_capturing(), NA)
        expect_error(stop_capturing(), NA)
    })
})
