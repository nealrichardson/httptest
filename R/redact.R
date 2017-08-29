#' Remove sensitive content from HTTP responses
#'
#' When recording requests for use as test fixtures, you don't want to include secrets like authentication tokens and personal ids. These functions provide a means for redacting this kind of content, or anything you want, from responses that [capture_requests()] saves.
#'
#' `redact_cookies()` removes cookies from 'httr' `response` objects. `redact_headers()` lets you target selected request and response headers for redaction. `redact_auth()` is a convenience wrapper around them for a useful default redactor in `capture_requests()`.
#'
#' @param response An 'httr' `response` object to sanitize. Redacting functions should take as their only argument a response object.
#' @param headers For `redact_headers()`, a character vector of header names to sanitize. Note that `redact_headers()` itself does not do redacting but returns a function that when called does the redacting.
#' @return Redacting functions must return a well-formed 'httr' `response` object. `redact_headers()` returns a redacting function, while `redact_auth()` and `redact_cookies()` themselves are redacting functions.
#' @name redact
#' @aliases redact_auth redact_cookies redact_headers
#' @export
redact_auth <- function (response) {
    response <- redact_cookies(response)
    response <- redact_headers(c("Authorization", "Proxy-Authorization"))(response)
    return(response)
}

#' @rdname redact
#' @export
redact_cookies <- function (response) {
    ## TODO: implement
    return(response)
}

#' @rdname redact
#' @export
redact_headers <- function (headers=c()) {
    return(function (r) {
        r$headers <- redact_from_header_list(r$headers, headers)
        r$all_headers <- redact_from_header_list(r$all_headers, headers)
        r$request$headers <- redact_from_header_list(r$request$headers, headers)
        return(r)
    })
}

redact_from_header_list <- function (headers, to_redact=c()) {
    bad <- tolower(names(headers)) %in% tolower(to_redact)
    headers[bad] <- rep(list("REDACTED"), sum(bad))
    return(headers)
}
