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

#' Make all HTTP requests return a fake 'response' object
#'
#' In this context, HTTP verb functions raise a 'message' so that test code can
#' assert that the requests are made. Unlike \code{\link{without_internet}},
#' the HTTP functions do not error and halt execution, instead returning a
#' \code{response}-class object so that code calling the HTTP functions can
#' proceed with its response handling logic and itself be tested.
#' @param expr Code to run inside the fake context
#' @return The result of \code{expr}
#' @export
with_fake_HTTP <- function (expr) {
    with_mock(
        `httr::GET`=fakeGET,
        `httr::PUT`=fakePUT,
        `httr::PATCH`=fakePATCH,
        `httr::POST`=fakePOST,
        `httr::DELETE`=fakeDELETE,
        `utils::download.file`=fakeDownload,
        eval.parent(expr)
    )
}
