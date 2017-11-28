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

mock_perform <- function (tracer, print=FALSE, ...) {
    suppressMessages(trace("request_perform", where=add_headers, print=print,
        tracer=tracer))
}

stop_mocking <- function () {
    suppressMessages(untrace("request_perform", where=add_headers))
}
