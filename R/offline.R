#' Skip tests that need an internet connection if you don't have one
#'
#' Temporary connection trouble shouldn't fail your build.
#'
#' Note that if you call this from inside one of the mock contexts, it will
#' follow the mock's behavior. That is, inside \code{\link{with_fake_HTTP}},
#' the check will pass and the following tests will run, but inside
#' \code{\link{without_internet}}, the following tests will be skipped.
#' @param message character message to be printed, passed to
#' \code{\link[testthat]{skip}}
#' @param url character URL to ping to check for a working connection
#' @return If offline, a test skip; else invisibly returns TRUE.
#' @seealso \code{\link[testthat]{skip}}
#' @importFrom testthat skip
#' @export
skip_if_disconnected <- function (message=paste("Offline: cannot reach", url),
                                  url="http://httpbin.org/") {
    if (currently_offline(url)) {
        skip(message)
    }
    invisible(TRUE)
}

#' @importFrom httr GET
currently_offline <- function (url="http://httpbin.org/") {
    inherits(try(httr::GET(url), silent=TRUE), "try-error")
}
