#' Make all HTTP requests raise an error
#'
#' `without_internet` simulates the situation when any network request will
#' fail, as in when you are without an internet connection. Any HTTP request
#' through the verb functions in `httr`, or [utils::download.file()], will raise
#' an error. The error message raised has a well-defined shape, made of three
#' elements, separated by space: (1) the request
#' method (e.g. "GET", or for downloading, "DOWNLOAD"); (2) the request URL; and
#' (3) the request body, if present. The verb-expectation functions,
#' such as [expect_GET()] and [expect_POST()], look for this shape.
#' @param expr Code to run inside the mock context
#' @return The result of `expr`
#' @importFrom testthat with_mock
#' @examples
#' without_internet({
#'     expect_error(httr::GET("http://httpbin.org/get"),
#'         "GET http://httpbin.org/get")
#'     expect_error(httr::PUT("http://httpbin.org/put",
#'         body='{"a":1}'),
#'         'PUT http://httpbin.org/put {"a":1}', fixed=TRUE)
#' })
#' @export
without_internet <- function (expr) {
    with_mock(
        `httr:::request_perform`=stopRequest,
        `utils::download.file`=stopDownload,
        eval.parent(expr)
    )
}

stopRequest <- function (req, handle, refresh) {
    out <- paste(req$method, req$url)
    body <- requestBody(req)
    if (!is.null(body)) {
        out <- paste(out, body)
    }
    if (!is.null(req$mockfile)) {
        ## Poked in here by mockRequest for ease of debugging
        ## Append it to the end.
        out <- paste0(out, " (", req$mockfile, ")")
    }
    stop(out, call.=FALSE)
}

stopDownload <- function (url, ...) {
    stop("DOWNLOAD ", url, call.=FALSE)
}
