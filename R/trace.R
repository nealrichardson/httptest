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

mock_perform <- function (mocker, print=FALSE, ...) {
    tracer <- substitute_q(fetch_tracer, list(.mocker=mocker))
    suppressMessages(trace("request_perform", where=add_headers, print=print,
        tracer=tracer))
}

stop_mocking <- function () {
    suppressMessages(untrace("request_perform", where=add_headers))
}

fetch_tracer <- quote({
    request_fetch <- function (x, url, handle) .mocker(req)
    parse_headers <- function (x) {
        if (length(resp$all_headers)) {
            return(resp$all_headers)
        } else {
            return(list(list(headers=x)))
        }
    }
    response <- function (...) {
        out <- structure(list(...), class="response")
        out$cookies <- resp$cookies
        out$handle <- NULL
        return(out)
    }
})

## cf http://adv-r.had.co.nz/Computing-on-the-language.html#substitute
substitute_q <- function (x, env) eval(substitute(substitute(y, env), list(y=x)))
