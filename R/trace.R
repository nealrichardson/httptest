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
    on.exit(safe_untrace(x, where=where))
    eval.parent(expr)
}

mock_perform <- function (mocker, ...) {
    tracer <- substitute_q(fetch_tracer, list(.mocker=mocker))
    # trace curl's form_file making the path normalization a no-op so that file
    # hashes are the same on different platforms
    quietly(trace(curl::form_file, quote(
        normalizePath <- function (path, ...) return(path)
    ), where=httr::upload_file, print=getOption("httptest.debug", FALSE)))
    # trace body_config to close the file connection that it creates when the
    # body inherits form_file
    quietly(trace("body_config", exit=quote(
        if (exists("con")) close.connection(con)
    ), where=httr::PUT, print=getOption("httptest.debug", FALSE)))

    invisible(trace_httr("request_perform", tracer=tracer, ...))
}

#' @importFrom utils sessionInfo
trace_httr <- function (..., print=getOption("httptest.debug", FALSE)) {
    ## Trace it as seen from within httr
    quietly(trace(..., print=print, where=add_headers))
    ## And if httr is attached and the function is exported, trace the
    ## function as the user sees it
    if ("httr" %in% names(sessionInfo()$otherPkgs) && ..1 %in% getNamespaceExports("httr")) {
        try(quietly(trace(..., print=print, where=sys.frame())))
    }
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
stop_mocking <- function () {
    safe_untrace(untrace(curl::form_file))
    invisible(safe_untrace("request_perform", add_headers))
}

safe_untrace <- function (what, where=sys.frame()) {
    ## If you attempt to untrace a function (1) that isn't exported from
    ## whatever namespace it lives in and (2) that isn't currently traced,
    ## it errors. This prevents that so that it's always safe to call `untrace`

    ## untrace() and get() handle enviroments differently
    if (is.environment(where)) {
        env <- where
    } else {
        env <- environment(where)
    }
    if (inherits(try(get(what, env), silent=TRUE), "functionWithTrace")) {
        quietly(untrace(what, where=where))
    }
}

## This is the code that we'll inject into `request_perform` to override some
## internal httr functions. Each mock context will provide its own `.mocker`
## that replaces the actual curl requesting and returns a response object.
fetch_tracer <- quote({
    request_fetch <- function (...) .mocker(req)
    parse_http_headers <- parse_headers <- function (x, ...) {
        # If we're loading a mock response, we've already parsed the headers,
        # so just use them.
        # In httr <= 1.3.1, the function was called parse_headers
        if (length(resp$all_headers)) {
            return(resp$all_headers)
        } else {
            return(list(list(headers=x)))
        }
    }
    pu <- httr::parse_url
    parse_url <- function (...) {
        # This is a workaround that forces all URLs to be HTTP because
        # httr > 1.3.1 supports non-HTTP and does different things with header
        # parsing for those requests. That broke some httptest tests that use
        # e.g. `GET("api/object1/")`.
        # TODO: stop supporting that, especially if httptest is the only
        # package that relies on the old behavior.
        out <- pu(...)
        out$scheme <- "http"
        out
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
