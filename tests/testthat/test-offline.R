test_that("currently_offline interacts with the mock contexts", {
  expect_message(
    expect_false(with_fake_http(currently_offline())),
    "GET http://httpbin.org/"
  )
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
    expect_message(
      with_fake_http({
        skip_if_disconnected("This should not skip")
        expect_failure(expect_true(FALSE))
      }),
      "GET http://httpbin.org/"
    )
  })
})
