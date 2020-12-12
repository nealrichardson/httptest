test_that("Functions not exported can be found", {
  expect_true(.internalFunction())
})

public({
  test_that("If a function is not exported, the public test context errors", {
    skip_if(pkgload::is_dev_package("httptest")) # load_all puts everything in the global env
    expect_error(
      .internalFunction(),
      'could not find function ".internalFunction"'
    )
  })
})
