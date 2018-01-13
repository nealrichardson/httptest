#' Test that an HTTP request is made with a header
#'
#' This expectation checks that a HTTP header (and potentially header value)
#' is present in a request. It works by inspecting the request object and
#' raising warnings that are caught by [testthat::expect_warning()].
#'
#' `expect_header` works both in the mock HTTP contexts and on "live" HTTP
#' requests.
#'
#' @param ... Arguments passed to `expect_warning`
#' @return `NULL`, according to `expect_warning`.
#' @importFrom httr add_headers
#' @importFrom testthat expect_warning
#' @examples
#' library(httr)
#' with_fake_http({
#'     expect_header(GET("http://example.com", config=add_headers(Accept="image/png")),
#'         "Accept: image/png")
#' })
#' @export
expect_header <- function (...) {
    tracer <- quote({
        heads <- req$headers
        for (h in names(heads)) {
            warning(paste(h, heads[h], sep=": "), call.=FALSE)
        }
    })
    with_trace("request_prepare", exit=tracer, where=add_headers, expr={
        expect_warning(...)
    })
}
