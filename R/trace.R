#' Wrapper around 'trace' to untrace when finished
#'
#' @param x Name of function to trace. See [base::trace()].
#' @param where where to look for the function to be traced.
#' @param print Logical: print a message every time the traced function is hit?
#' Default is `FALSE`; note that in `trace`, the default is `TRUE`.
#' @param ... Additional arguments to pass to `trace`. At minimum, must include
#' either `tracer` or `exit`.
#' @param expr Code to run inside the context
#' @return The result of `expr`
#' @export
#' @keywords internal
with_trace <- function (x, where=topenv(parent.frame()), print=getOption("httptest.debug", FALSE), ..., expr) {
    quietly(trace(x, print=print, where=where, ...))
    on.exit(quietly(untrace(x, where=where)))
    eval.parent(expr)
}

mock_perform <- function (mocker, ...) {
    tracer <- substitute_q(fetch_tracer, list(.mocker=mocker))
    invisible(trace_httr("request_perform", tracer=tracer, ...))
}

trace_httr <- function (..., print=getOption("httptest.debug", FALSE)) {
    quietly(trace(..., print=print, where=add_headers))
}

quietly <- function (expr) {
    env <- parent.frame()
    if (getOption("httptest.debug", FALSE)) {
        eval(expr, env)
    } else {
        suppressMessages(eval(expr, env))
    }
}

#' Turn off request mocking
#'
#' This function "untraces" the `httr` request functions so that normal, real
#' requesting behavior can be resumed.
#' @return Nothing; called for its side effects
#' @export
stop_mocking <- function () safe_untrace("request_perform", add_headers)

safe_untrace <- function (what, where) {
    ## If you attempt to untrace a function (1) that isn't exported from
    ## whatever namespace it lives in and (2) that isn't currently traced,
    ## it errors. This prevents that so that it's always safe to call `untrace`
    if (inherits(get(what, environment(where)), "functionWithTrace")) {
        quietly(untrace(what, where=where))
    }
}

## This is the code that we'll inject into `request_perform` to override some
## internal httr functions. Each mock context will provide its own `.mocker`
## that replaces the actual curl requesting and returns a response object.
fetch_tracer <- quote({
    request_fetch <- function (...) .mocker(req)
    parse_headers <- function (x, ...) {
        # If we're loading a mock response, we've already parsed the headers,
        # so just use them.
        if (length(resp$all_headers)) {
            return(resp$all_headers)
        } else {
            return(list(list(headers=x)))
        }
    }
    response <- function (...) {
        out <- structure(list(...), class="response")
        # Remove some curl objects/pointers
        out$cookies <- resp$cookies
        out$handle <- NULL
        return(out)
    }
})

## cf http://adv-r.had.co.nz/Computing-on-the-language.html#substitute
substitute_q <- function (x, env) eval(substitute(substitute(y, env), list(y=x)))
