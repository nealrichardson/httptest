#' Make all HTTP requests raise an error
#' @param expr Code to run inside the mock context
#' @return The result of \code{expr}
#' @importFrom testthat with_mock
#' @export
without_internet <- function (expr) {
    with_mock(
        `httr::GET`=function (url, ...) halt("GET ", url),
        `httr::PUT`=function (url, body=NULL, ...) halt("PUT ", url, " ", body),
        `httr::PATCH`=function (url, body=NULL, ...) halt("PATCH ", url, " ", body),
        `httr::POST`=function (url, body=NULL, ...) halt("POST ", url, " ", body),
        `httr::DELETE`=function (url, ...) halt("DELETE ", url),
        `utils::download.file`=function (url, ...) halt("DOWNLOAD ", url),
        eval.parent(expr)
    )
}

halt <- function (...) stop(..., call.=FALSE)
