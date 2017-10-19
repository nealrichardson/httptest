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
#' @param response An 'httr' `response` object to sanitize. Redacting functions
#' should take as their only argument a response object.
#' @param headers For `redact_headers()`, a character vector of header names to
#' sanitize. Note that `redact_headers()` itself does not do redacting but
#' returns a function that when called does the redacting.
#' @param FUN For `within_body_text()`, a function that takes as its argument a
#' character vector and returns a modified version of that. This function will
#' be applied to the text of the response's "content".
#' @return Redacting functions must return a well-formed 'httr' `response`
#' object. `redact_auth()`, `redact_HTTP_auth()`, and `redact_cookies()`
#' themselves are redacting functions, while `redact_headers()` and
#' `within_body_text()` return redacting functions.
#' @name redact
#' @aliases redact_auth redact_cookies redact_headers redact_HTTP_auth redact_oauth within_body_text
#' @seealso `vignette("redacting", package="httptest")` for a detailed discussion of what these functions do and how to customize them.
#' @export
redact_auth <- function (response) {
    response <- redact_cookies(response)
    response <- redact_headers(c("Authorization", "Proxy-Authorization"))(response)
    response <- redact_HTTP_auth(response)
    response <- redact_oauth(response)
    return(response)
}

#' @rdname redact
#' @export
redact_cookies <- function (response) {
    ## Delete from request
    if ("cookie" %in% names(response$request$options)) {
        response$request$options$cookie <- "REDACTED"
    }
    ## Delete from response
    response <- redact_headers("Set-Cookie")(response)
    if (!is.null(response$cookies) && nrow(response$cookies)) {
        ## is.null check is for reading mocks.
        ## possible TODO: add $cookies to fakeResponse, then !is.null isn't needed
        response$cookies$value <- "REDACTED"
    }
    return(response)
}

#' @rdname redact
#' @export
redact_headers <- function (headers=c()) {
    return(function (r) {
        r$headers <- redact_from_header_list(r$headers, headers)
        r$all_headers <- lapply(r$all_headers, function (h) {
            h$headers <- redact_from_header_list(h$headers, headers)
            return(h)
        })
        r$request$headers <- redact_from_header_list(r$request$headers, headers)
        return(r)
    })
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
    response <- redact_headers("Authorization")(response)
    return(response)
}

#' @rdname redact
#' @export
within_body_text <- function (FUN) {
    return(function (response) {
        old <- suppressMessages(content(response, "text"))
        new <- FUN(old)
        response$content <- charToRaw(new)
        return(response)
    })
}
