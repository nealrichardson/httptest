#' Set mocking/capturing state for a vignette
#'
#' Use `start_vignette()` to either use previously recorded responses or capture
#' real responses for future use, depending on the value of the `RECORD`
#' environment variable.
#'
#' In a vignette or other R Markdown or Sweave document, place
#' `start_vignette()` in an R code block at the beginning,
#' before the first API request is made, and put
#' `end_vignette()` in a R code chunk at the end. You may
#' want to make those R code chunks have `echo=FALSE` in order to hide the fact
#' that you're calling them.
#'
#' The environment variable `RECORD` determines whether you're making real
#' requests and capturing them or whether you're loading previously recorded
#' mocks. If `RECORD` is `true` (or `TRUE`: it's case insensitive),
#' `start_vignette()` calls [start_capturing()]. Otherwise (by default), it
#' calls [use_mock_API()].
#'
#' @param ... Optional arguments passed to `start_capturing()`
#' @return Nothing; called for its side effect of starting/ending
#' response recording or mocking.
#' @export
#' @seealso [start_capturing()] [use_mock_API()] `vignette("vignettes", package="httptest")`
start_vignette <- function (...) {
    ## Cache the original .mockPaths so we can restore it on exit?
    # options(httptest.mock.paths.old=getOption("httptest.mock.paths")
    if (identical(toupper(Sys.getenv("RECORD")), "TRUE")) {
        suppressMessages(start_capturing(...))
    } else {
        use_mock_API()
    }
}

#' @rdname start_vignette
#' @export
end_vignette <- function () {
    if (identical(toupper(Sys.getenv("RECORD")), "TRUE")) {
        stop_capturing()
    } else {
        stop_mocking()
    }
    ## Restore original .mockPaths?
    # options(
    #     httptest.mock.paths=getOption("httptest.mock.paths.old"),
    #     httptest.mock.paths.old=NULL,
    # )
}
