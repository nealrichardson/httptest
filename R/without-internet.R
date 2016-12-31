#' Make all HTTP requests raise an error
#' @param expr Code to run inside the mock context
#' @return The result of \code{expr}
#' @importFrom testthat with_mock
#' @export
without_internet <- function (expr) {
    with_mock(
        `httr:::request_perform`=stopRequest,
        `utils::download.file`=function (url, ...) stop("DOWNLOAD ", url, call.=FALSE),
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
