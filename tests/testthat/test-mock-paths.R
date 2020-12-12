public({
  test_that(".mockPaths works more or less like .libPaths", {
    expect_identical(.mockPaths(), ".")
    .mockPaths("something else")
    expect_identical(.mockPaths(), c("something else", "."))
    # Unique paths
    .mockPaths(".")
    expect_identical(.mockPaths(), c(".", "something else"))
    .mockPaths(NULL)
    expect_identical(.mockPaths(), ".")
  })

  test_that(".mockPaths default path prefers to be in tests/testthat", {
    d <- tempfile()
    dir.create(file.path(d, "tests", "testthat"), recursive = TRUE)
    old <- setwd(d)
    on.exit(setwd(old))

    expect_identical(.mockPaths(), "tests/testthat")
  })

  with_mock_api({
    test_that("GET with no query, default mock path", {
      b <- GET("api/object1/")
      expect_identical(content(b), list(object = TRUE))
    })
    test_that("GET with query, default mock path", {
      obj <- GET("api/object1/", query = list(a = 1))
      expect_json_equivalent(
        content(obj),
        list(query = list(a = 1), mocked = "yes")
      )
    })
    test_that("There is no api/object2/ mock", {
      expect_GET(GET("api/object2/"))
    })

    .mockPaths("alt")
    test_that("GET with query, different mock path", {
      obj <- GET("api/object1/", query = list(a = 1))
      expect_json_equivalent(
        content(obj),
        list(query = list(a = 1), mocked = "twice")
      )
    })
    test_that("Now there is an api/object2/ mock", {
      obj <- GET("api/object2/")
      expect_identical(content(obj), list(object2 = TRUE))
    })
    test_that("If the primary mock dir doesn't have a mock, it passes to next", {
      b <- GET("api/object1/")
      expect_identical(content(b), list(object = TRUE))
    })
    test_that("Failure to find a mock in any dir", {
      expect_GET(GET("api/NOTAFILE/"))
    })

    .mockPaths(NULL)
    test_that("NULL mockPaths resets to default", {
      obj <- GET("api/object1/", query = list(a = 1))
      expect_json_equivalent(
        content(obj),
        list(query = list(a = 1), mocked = "yes")
      )
      expect_GET(GET("api/object2/"))
    })
  })
})
