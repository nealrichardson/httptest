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
#' @param ignore.case logical: if `FALSE`, the pattern matching is _case
#' sensitive_ and if `TRUE`, case is ignored during matching. Default is `TRUE`;
#' note that this is the opposite of `expect_warning` but is appropriate here
#' because HTTP header names are case insensitive.
#' @return `NULL`, according to `expect_warning`.
#' @importFrom httr add_headers
#' @importFrom testthat expect_warning
#' @examples
#' library(httr)
#' with_fake_http({
#'   expect_header(
#'     GET("http://example.com", config = add_headers(Accept = "image/png")),
#'     "Accept: image/png"
#'   )
#' })
#' @export
expect_header <- function(..., ignore.case = TRUE) {
  tracer <- quote({
    heads <- req$headers
    msgs <- lapply(names(heads), function(h) paste(h, heads[h], sep = ": "))
    warning(msgs, call. = FALSE)
  })
  with_trace("request_prepare", exit = tracer, where = add_headers, expr = {
    expect_warning(..., ignore.case = ignore.case)
  })
}
