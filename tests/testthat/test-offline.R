context("Offline checking and skipping")

test_that("currently_offline interacts with the mock contexts", {
    expect_false(with_fake_http(currently_offline()))
    expect_true(without_internet(currently_offline()))
})

public({
    test_that("skip_if_disconnected when disconnected", {
        without_internet({
            skip_if_disconnected("This should skip")
            expect_true(FALSE)
        })
    })
    test_that("skip_if_disconnected when 'connected'", {
        with_fake_http({
            skip_if_disconnected("This should not skip")
            expect_failure(expect_true(FALSE))
        })
    })
})
