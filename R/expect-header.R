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
#' with_fake_HTTP({
#'     expect_header(GET("http://example.com", config=add_headers(Accept="image/png")),
#'         "Accept: image/png")
#' })
#' @export
expect_header <- function (...) {
    tracer <- quote({
        # This is borrowed from what happens inside of httr:::request_prepare
        heads <- c(add_headers(Accept = "application/json, text/xml, application/xml, */*"),
            getOption("httr_config"), req)$headers
        for (h in names(heads)) {
            warning(paste(h, heads[h], sep=": "), call.=FALSE)
        }
    })
    # Magically, this seems to trace even in the mocked versions of this
    with_trace("request_perform", tracer=tracer, at=1, where=add_headers, expr={
        expect_warning(...)
    })
}

#' Wrapper around 'trace' to untrace when finished
#'
#' @param x Name of function to trace. See [base::trace()].
#' @param where where to look for the function to be traced.
#' @param print Logical: print a message every time the traced function is hit?
#' Default is `FALSE`; note that in `trace`, the default is `TRUE`.
#' @param ... Additional arguments to pass to `trace`. At minimum, must include
#' either `tracer` and `at`, or `exit`.
#' @param expr Code to run inside the context
#' @return The result of `expr`
#' @export
with_trace <- function (x, where=topenv(parent.frame()), print=FALSE, ..., expr) {
    suppressMessages(trace(x, print=print, where=where, ...))
    on.exit(suppressMessages(untrace(x, where=where)))
    eval.parent(expr)
}
