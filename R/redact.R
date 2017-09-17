#' Remove sensitive content from HTTP responses
#'
#' When recording requests for use as test fixtures, you don't want to include secrets like authentication tokens and personal ids. These functions provide a means for redacting this kind of content, or anything you want, from responses that [capture_requests()] saves.
#'
#' `redact_cookies()` removes cookies from 'httr' `response` objects. `redact_headers()` lets you target selected request and response headers for redaction. `redact_HTTP_auth()` removes `username:password`-based HTTP auth credentials. `redact_auth()` is a convenience wrapper around them for a useful default redactor in `capture_requests()`.
#'
#' @param response An 'httr' `response` object to sanitize. Redacting functions should take as their only argument a response object.
#' @param headers For `redact_headers()`, a character vector of header names to sanitize. Note that `redact_headers()` itself does not do redacting but returns a function that when called does the redacting.
#' @return Redacting functions must return a well-formed 'httr' `response` object. `redact_headers()` returns a redacting function, while `redact_auth()`, `redact_HTTP_auth()`, and `redact_cookies()` themselves are redacting functions.
#' @name redact
#' @aliases redact_auth redact_cookies redact_headers redact_HTTP_auth
#' @export
redact_auth <- function (response) {
    response <- redact_cookies(response)
    response <- redact_headers(c("Authorization", "Proxy-Authorization"))(response)
    response <- redact_HTTP_auth(response)
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
