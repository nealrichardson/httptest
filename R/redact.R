chain_redactors <- function (funs) {
    ## Given a list of functions, return a function that execs them in sequence
    return(function (response) {
        for (f in funs) {
            response <- f(response)
        }
        return(response)
    })
}

#' Remove sensitive content from HTTP responses
#'
#' When recording requests for use as test fixtures, you don't want to include
#' secrets like authentication tokens and personal ids. These functions provide
#' a means for redacting this kind of content, or anything you want, from
#' responses that [capture_requests()] saves.
#'
#' `redact_cookies()` removes cookies from 'httr' `response` objects.
#' `redact_headers()` lets you target selected request and response headers for
#' redaction. `redact_HTTP_auth()` removes `username:password`-based HTTP auth
#' credentials. `redact_oauth()` removes the OAuth 'Token' object that 'httr'
#' sticks in the request object. `redact_auth()` is a convenience wrapper around
#' them for a useful default redactor in `capture_requests()`.
#'
#' `within_body_text()` lets you manipulate the text of the response body
#' and manages the parsing of the raw (binary) data in the 'response' object.
#'
#' @param response An 'httr' `response` object to sanitize.
#' @param headers For `redact_headers()`, a character vector of header names to
#' sanitize. Note that `redact_headers()` itself does not do redacting but
#' returns a function that when called does the redacting.
#' @param FUN For `within_body_text()`, a function that takes as its argument a
#' character vector and returns a modified version of that. This function will
#' be applied to the text of the response's "content".
#' @return All redacting functions return a well-formed 'httr' `response`
#' object.
#' @name redact
#' @aliases redact_auth redact_cookies redact_headers redact_HTTP_auth redact_oauth within_body_text
#' @seealso `vignette("redacting", package="httptest")` for a detailed discussion of what these functions do and how to customize them. [gsub_response()] is another redactor.
#' @export
redact_auth <- chain_redactors(list(
    redact_cookies,
    as.redactor(redact_headers(c("Authorization", "Proxy-Authorization"))),
    redact_HTTP_auth,
    redact_oauth
))

#' @rdname redact
#' @export
redact_cookies <- function (response) {
    ## Delete from request
    if ("cookie" %in% names(response$request$options)) {
        response$request$options$cookie <- "REDACTED"
    }
    ## Delete from response
    response <- redact_headers(response, "Set-Cookie")
    if (!is.null(response$cookies) && nrow(response$cookies)) {
        ## is.null check is for reading mocks.
        ## possible TODO: add $cookies to fakeResponse, then !is.null isn't needed
        response$cookies$value <- "REDACTED"
    }
    return(response)
}

#' @rdname redact
#' @export
redact_headers <- function (response, headers=c()) {
    response$headers <- redact_from_header_list(response$headers, headers)
    response$all_headers <- lapply(response$all_headers, function (h) {
        h$headers <- redact_from_header_list(h$headers, headers)
        return(h)
    })
    response$request$headers <- redact_from_header_list(response$request$headers,
        headers)
    return(response)
}

redact_from_header_list <- function (headers, to_redact=c()) {
    bad <- tolower(names(headers)) %in% tolower(to_redact)
    headers[bad] <- "REDACTED"
    return(headers)
}

#' @rdname redact
#' @export
redact_HTTP_auth <- function (response) {
    if ("userpwd" %in% names(response$request$options)) {
        response$request$options$userpwd <- "REDACTED"
    }
    return(response)
}

#' @rdname redact
#' @export
redact_oauth <- function (response) {
    response$request$auth_token <- NULL
    return(redact_headers(response, "Authorization"))
}

#' @rdname redact
#' @export
within_body_text <- function (response, FUN) {
    old <- suppressMessages(content(response, "text"))
    new <- FUN(old)
    response$content <- charToRaw(new)
    return(response)
}

#' Find and replace within a 'response'
#'
#' This function passes its arguments to [base::gsub()] in order to find and
#' replace string patterns (regular expressions) in three attributes of an
#' `httr` 'response' object: (1) the response body; (2) the response URL; and
#' (3) the request URL (that is, the URL appears twice in the response object).
#'
#' Note that, unlike `gsub()`, the first argument of the function is `response`,
#' not `pattern`, while the equivalent argument in `gsub()`, "`x`", is placed
#' third. This difference is to maintain consistency with the other redactor
#' functions in `httptest`, which all take `response` as the first argument.
#' @param response An 'httr' `response` object to sanitize.
#' @param pattern From [base::gsub()]: "character string containing a regular
#' expression (or character string for `fixed = TRUE`) to be matched in the
#' given character vector." Passed to `gsub()`. See the docs for `gsub()` for
#' further details.
#' @param replacement A replacement for the matched pattern, possibly including
#' regular expression backreferences. Passed to `gsub()`. See the docs for
#' `gsub()` for further details.
#' @param ... Additional logical arguments passed to `gsub()`: `ignore.case`,
#' `perl`, `fixed`, and `useBytes` are the possible options.
#' @return A `response` object with the pattern replaced in the URLs and
#' response body.
#' @export
gsub_response <- function (response, pattern, replacement, ...) {
    replacer <- function (x) gsub(pattern, replacement, x, ...)
    # Sub in URL--note that it appears twice!
    response$url <- replacer(response$url)
    response$request$url <- replacer(response$request$url)
    # Now remove from the response body
    response <- within_body_text(response, replacer)
    return(response)
}

#' Wrap a redacting expression as a proper function
#'
#' Redactors take a `response` as their first argument, and some take additional
#' arguments: `redact_headers()`, for example, requires that you specify
#' `headers`. This function allows you to take a simplified expression like what
#' you would include in a `magrittr` pipe chain and generate the
#' `function (response, ...)` for you so that you can provide the function to
#' `capture_requests()`.
#'
#' For example, `as.redactor(redact_headers("X-Custom-Header"))` is equivalent
#' to `function (response) redact_headers(response, "X-Custom-Header")`. This
#' allows you to do
#' `capture_requests(redact = as.redactor(redact_headers("X-Custom-Header")))`.
#' @param expr Partial expression to turn into a function of `response`
#' @return A `function`.
#' @rdname as-redactor
#' @export
as.redactor <- function (expr) {
    env <- parent.frame()
    expr <- substitute(expr)
    # cf. magrittr:::prepare_first: inject a first argument into the expression
    expr <- as.call(c(expr[[1L]], quote(response), as.list(expr[-1L])))
    # cf. magrittr:::wrap_function: wrap that in a function (response) ...
    return(eval(call("function", as.pairlist(alist(response=)), expr), env, env))
}
