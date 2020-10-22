#' Use or create mock files depending on their existence
#'
#' This context will switch the [`.mockPaths()`] to `tests/testthat/dir`
#' (and then resets it to what it was before).
#' If the `tests/testthat/dir` folder doesn't exist, [`capture_requests()`] will
#' be run to create mocks.
#' If it exists, [`with_mock_api()`] will be run.
#' To re-record mock files, simply delete `tests/testthat/dir` and run the test.
#'
#' @param dir character string, unique folder name that will be used or created
#' under `tests/testthat/`
#' @inheritParams with_mock_api
#'
#' @export
#'
with_mock_dir <- function(dir, expr) {
  dir <- testthat::test_path(dir)
  current_mockPaths <- httptest::.mockPaths()

  # Change mockPaths...
  httptest::.mockPaths(dir)
  # And clean up later
  withr::defer({
    httptest::.mockPaths(NULL)
    httptest::.mockPaths(current_mockPaths)
  })

  if (dir.exists(dir)) {
    ## We already have recorded, so use the fixtures
    withr::with_envvar(
      new = c("GITHUB_PAT" = "foobar"),
      httptest::with_mock_api(...)
    )
  } else {
    ## Record!
    httptest::capture_requests(...)
  }

}
