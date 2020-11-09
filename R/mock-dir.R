#' Use or create mock files depending on their existence
#'
#' This context will switch the [.mockPaths()] to `tests/testthat/dir`
#' (and then resets it to what it was before).
#' If the `tests/testthat/dir` folder doesn't exist, [capture_requests()] will
#' be run to create mocks.
#' If it exists, [with_mock_api()] will be run.
#' To re-record mock files, simply delete `tests/testthat/dir` and run the test.
#'
#' @param dir character string, unique folder name that will be used or created
#' under `tests/testthat/`
#' @inheritParams with_mock_api
#' @inheritParams start_capturing
#'
#' @export
#'
with_mock_dir <- function(dir, expr, simplify = TRUE) {

  if (!nzchar(Sys.getenv("TESTING_MOCK_DIR"))) {
    dir <- testthat::test_path(dir)
  }


  if (dir.exists(dir)) {
    ## We already have recorded, so use the fixtures
   with_mock_path(
     dir,
     with_mock_api(expr),
     replace = TRUE
     )
  } else {
    ## Record!
    with_mock_path(
      dir,
      capture_requests(expr, simplify = simplify),
      replace = TRUE
      )
  }

}
