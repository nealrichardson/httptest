#' Expecations for mocked HTTP requests
#'
#' The mock contexts in `httptest` can raise errors or messages when requests
#' are made, and those (error) messages have three
#' elements, separated by space: (1) the request
#' method (e.g. "GET"); (2) the request URL; and
#' (3) the request body, if present.
#' These verb-expectation functions look for this message shape. `expect_PUT`,
#' for instance, looks for a request message that starts with "PUT".
#'
#' @param object Code to execute that may cause an HTTP request
#' @param url character: the URL you expect a request to be made to. Default is
#' an empty string, meaning that you can just assert that a request is made with
#' a certain method without asserting anything further.
#' @param ... character segments of a request payload you expect to be included
#' in the request body, to be joined together by `paste0`
#' @return A `testthat` 'expectation'.
#' @examples
#' library(httr)
#' without_internet({
#'     expect_GET(GET("http://httpbin.org/get"),
#'         "http://httpbin.org/get")
#'     expect_PUT(PUT("http://httpbin.org/put", body='{"a":1}'),
#'         'http://httpbin.org/put',
#'         '{"a":1}')
#'     expect_PUT(PUT("http://httpbin.org/put", body='{"a":1}'))
#'     expect_no_request(rnorm(5))
#' })
#' @name expect-verb
#' @aliases expect_GET expect_POST expect_PUT expect_PATCH expect_DELETE expect_no_request
#' @export
expect_GET <- function (object, url="", ...) {
    expect_mock_request(object, "GET ", url)
}

#' @rdname expect-verb
#' @export
expect_POST <- function (object, url="", ...) {
    expect_mock_request(object, "POST ", url, " ", ...)
}

#' @rdname expect-verb
#' @export
expect_PATCH <- function (object, url="", ...) {
    expect_mock_request(object, "PATCH ", url, " ", ...)
}

#' @rdname expect-verb
#' @export
expect_PUT <- function (object, url="", ...) {
    expect_mock_request(object, "PUT ", url, " ", ...)
}

#' @rdname expect-verb
#' @export
expect_DELETE <- function (object, url="") {
    expect_mock_request(object, "DELETE ", url)
}

#' @rdname expect-verb
#' @export
expect_no_request <- function (object, ...) {
    ## No request means no error/message thrown
    request_happened(object, NA)
}

#' @importFrom testthat expect_error
expect_mock_request <- function (object, ...) {
    expected <- sub(" +$", "", paste0(...)) ## PUT/POST/PATCH with no body may have trailing whitespace
    request_happened(object, expected, fixed=TRUE)
}

## Without internet, POST/PUT/PATCH throw errors with their request info
## With fake HTTP, POST/PUT/PATCH print messages with their request info.
## with_fake_HTTP mocks request_happened to make it expect_message
request_happened <- testthat::expect_error
