#' Make all HTTP requests raise an error
#' @param expr Code to run inside the mock context
#' @return The result of \code{expr}
#' @importFrom testthat with_mock
#' @examples
#' without_internet({
#'     expect_error(httr::GET("http://httpbin.org/get"),
#'         "GET http://httpbin.org/get")
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
    body <- req$options$postfields
    if (!is.null(body)) {
        out <- paste(out, rawToChar(body))
    }
    stop(out, call.=FALSE)
}

stopDownload <- function (url, ...) {
    stop("DOWNLOAD ", url, call.=FALSE)
}
