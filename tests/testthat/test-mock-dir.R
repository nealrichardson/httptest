public({
  test_that("with_mock_dir works when the directory with mock files exists", {
    temporary_dir <- tempfile()
    # The directory exists, so we'll read mocks from it
    dir.create(temporary_dir)
    # Put mocks in it
    file.copy(testthat::test_path("httpbin.org"), temporary_dir, recursive = TRUE)

    current_mock_paths <- .mockPaths()
    with_mock_dir(temporary_dir, {
      # There's nothing on the mock paths other than our mock dir
      expect_identical(.mockPaths(), temporary_dir)
      expect_no_request(resp <- GET("http://httpbin.org/status/204"))
      # We've read from the mock
      expect_equal(headers(resp)$date, "Sat, 24 Feb 2018 00:22:11 GMT")
    })
    # Original mock paths are reset
    expect_true(all.equal(current_mock_paths, .mockPaths()))
  })

  test_that("with_mock_dir creates mock files directory", {
    skip_if_disconnected()
    temporary_dir <- tempfile()
    current_mock_paths <- .mockPaths()
    with_mock_dir(temporary_dir, {
      # Since the directory doesn't exist, we will create it and capture
      expect_identical(.mockPaths(), temporary_dir)
      # The first one makes the request
      resp <- GET("http://httpbin.org/status/204")
      # And it's a real request, not using our fixture
      expect_false(headers(resp)$date == "Sat, 24 Feb 2018 00:22:11 GMT")
    })
    expect_true(all.equal(current_mock_paths, .mockPaths()))
  })

  test_that("with_mock_dir prefers to be in tests/testthat", {
    d <- tempfile()
    dir.create(file.path(d, "tests", "testthat"), recursive = TRUE)
    old <- setwd(d)
    on.exit(setwd(old))

    with_mock_dir("asdf", {
      expect_identical(.mockPaths(), file.path("tests", "testthat", "asdf"))
    })
    with_mock_dir("/asdf", {
      expect_identical(.mockPaths(), "/asdf")
    })
  })
})
