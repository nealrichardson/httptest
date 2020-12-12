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

test_that("quietly muffles messages, conditional on httptest.debug", {
  expect_message(quietly(message("A message!")), NA)
  options(httptest.debug = TRUE)
  on.exit(options(httptest.debug = NULL))
  expect_message(quietly(message("A message!")), "A message!")
})
