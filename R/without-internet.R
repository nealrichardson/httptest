#' Make all HTTP requests raise an error
#' @param expr Code to run inside the mock context
#' @return The result of `expr`
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
    body <- requestBody(req)
    if (length(body) > 0) {
        out <- paste(out, rawToChar(body))
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
