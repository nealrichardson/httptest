context("Offline checking and skipping")

test_that("currently_offline interacts with the mock contexts", {
    expect_false(with_fake_HTTP(currently_offline()))
    expect_true(without_internet(currently_offline()))
})

public({
    test_that("skip_if_disconnected", {
        without_internet({
            skip_if_disconnected("This should skip")
            expect_true(FALSE)
        })
    })
})
