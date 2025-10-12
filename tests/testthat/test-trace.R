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

  FUNS <- list(
    httr = c('request_perform', 'body_config'),
    curl = c('form_file')
  )

  .are_pkgs_traced <- function() {
    .process_fun <- function(fun, pkg) {
      inherits(getFromNamespace(fun, pkg), "functionWithTrace")
    }
    .process_pkg <- function(pkg) {
      sapply(FUNS[[pkg]], .process_fun, pkg = pkg)
    }
    unlist(lapply(names(FUNS), .process_pkg))
  }

  with_mock_api({
    test_that("curl/httr functions are properly traced", {
      expect_true(all(.are_pkgs_traced()))
    })
  })

  test_that("curl/httr functions are properly untraced", {
    expect_false(any(.are_pkgs_traced()))
  })
})

test_that("quietly muffles messages, conditional on httptest.debug", {
  expect_message(quietly(message("A message!")), NA)
  options(httptest.debug = TRUE)
  on.exit(options(httptest.debug = NULL))
  expect_message(quietly(message("A message!")), "A message!")
})
