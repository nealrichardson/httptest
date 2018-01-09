#' Collect API Responses as Mock Files
#'
#' `capture_requests` is a context that collects the responses from requests
#' you make and stores them as mock files. This enables you to perform a series
#' of requests against a live server once and then build your test suite using
#' those mocks, running your tests in [with_mock_API()].
#'
#' `start_capturing` and `stop_capturing` allow you to turn on/off request
#' recording for more convenient use in an interactive session.
#'
#' Mocks stored by this context are written out as plain-text files, either with
#' extension `.json` if the request returned JSON content or with extension `.R`
#' otherwise. The `.R` files contain syntax that when executed recreates the
#' `httr` "response" object. By storing fixtures as plain-text files, you can
#' more easily confirm that your mocks look correct, and you can more easily
#' maintain them without having to re-record them. If the API changes subtly,
#' such as when adding an additional attribute to an object, you can just touch
#' up the mocks.
#'
#' @section Redacting:
#'
#' You can provide a function that alters the response content being written
#' out, allowing you to remove sensitive values, such as authentication tokens,
#' as well as any other modification or truncation of the response body. By
#' default, the [redact_auth()] function will be used to purge standard
#' auth methods, but you can provide an alternative redacting function in
#' several ways. You can provide in the `redact` argument of
#' `capture_requests`/`start_capturing`:
#'
#' * A function taking a single argument, the `response`, and returning a valid
#' `response` object.
#' * A formula as shorthand for an anonymous function with `.` as the
#' "response" argument, as in the `purrr` package. That is, instead of
#' `function (response) redact_headers(response, "X-Custom-Header")`, you can
#' use `~ redact_headers(., "X-Custom-Header")`
#' * A list of redacting functions/formulas, which will be executed
#' in sequence on the response
#'
#' Alternatively, you can put a redacting function in `inst/httptest/redact.R`
#' in your package, and
#' any time your package is loaded (as in when running tests or building
#' vignettes), this function will be used automatically.
#'
#' For further details on how to redact responses, see `vignette("redacting")`.
#'
#' @param expr Code to run inside the context
#' @param path Where to save the mock files. Default is the first directory in
#' [.mockPaths()], which if not otherwise specified is the current working
#' directory.
#' @param simplify logical: if `TRUE` (default), JSON responses with status 200
#' will be written as just the text of the response body. In all other cases,
#' and when `simplify` is `FALSE`, the "response" object will be written out to
#' a .R file using [base::dput()].
#' @param verbose logical: if `TRUE`, a `message` is printed for every file
#' that is written when capturing requests containing the absolute path of the
#' file. Useful for debugging if you're capturing but don't see the fixture
#' files being written in the expected location. Default is `FALSE`.
#' @param redact function to run to purge sensitive strings from the recorded
#' response objects. See the "Redacting" section for details.
#' @param ... Arguments passed through `capture_requests` to `start_capturing`
#' @return `capture_requests` returns the result of `expr`. `start_capturing`
#' invisibly returns the `path` it is given. `stop_capturing` returns nothing;
#' it is called for its side effects.
#' @examples
#' \dontrun{
#' capture_requests({
#'     GET("http://httpbin.org/get")
#'     GET("http://httpbin.org")
#'     GET("http://httpbin.org/response-headers",
#'         query=list(`Content-Type`="application/json"))
#' })
#' # Or:
#' start_capturing()
#' GET("http://httpbin.org/get")
#' GET("http://httpbin.org")
#' GET("http://httpbin.org/response-headers",
#'     query=list(`Content-Type`="application/json"))
#' stop_capturing()
#' }
#' @importFrom httr content
#' @export
capture_requests <- function (expr, path, ...) {
    start_capturing(...)
    on.exit(stop_capturing())
    where <- parent.frame()
    if (!missing(path)) {
        with_mock_path(path, eval(expr, where))
    } else {
        eval(expr, where)
    }
}

#' @rdname capture_requests
#' @export
start_capturing <- function (path,
                             simplify=TRUE,
                             verbose=FALSE,
                             redact=default_redactor()) {
    if (!missing(path)) {
        ## Note that this changes state and doesn't reset it
        .mockPaths(path)
    } else {
        path <- NULL
    }

    options(httptest.redactor=prepare_redactor(redact))

    ## Use "substitute" so that args get inserted. Code remains quoted.
    req_tracer <- substitute({
        ## Get the value returned from the function, and sanitize it
        redactor <- get_current_redactor()
        .resp <- redactor(returnValue())
        f <- save_response(.resp, simplify=simplify)
        if (isTRUE(getOption("httptest.verbose", verbose))) {
            message("Writing ", normalizePath(f))
        }
    }, list(simplify=simplify, verbose=verbose))
    for (verb in c("PUT", "POST", "PATCH", "DELETE", "VERB", "GET")) {
        trace_httr(verb, exit=req_tracer, print=FALSE)
    }
    invisible(path)
}

#' Write out a captured response
#'
#' @param response An 'httr' `response` object
#' @param simplify logical: if `TRUE` (default), JSON responses with status 200
#' will be written as just the text of the response body. In all other cases,
#' and when `simplify` is `FALSE`, the "response" object will be written out to
#' a .R file using [base::dput()].
#' @return The character file name that was written out
#' @export
save_response <- function (response, simplify=TRUE) {
    ## Construct the mock file path
    filename <- file.path(.mockPaths()[1], buildMockURL(response$request))
    dir.create(dirname(filename), showWarnings=FALSE, recursive=TRUE)

    ## Omit curl handle C pointer, which doesn't serialize meaningfully
    response$handle <- NULL

    ## Get the Content-Type
    ct <- unlist(response$headers[tolower(names(response$headers)) == "content-type"])
    is_json <- any(grepl("application/json", ct))
    if (simplify && response$status_code == 200 && is_json) {
        ## Squelch the "No encoding supplied: defaulting to UTF-8."
        ## TODO: support other text content-types than JSON
        cat(suppressMessages(content(response, "text")), file=filename)
    } else {
        ## Dump an object that can be sourced

        ## Change the file extension to .R
        filename <- sub("json$", "R", filename)

        ## If content is text, rawToChar it and dput it as charToRaw(that)
        ## so that it loads correctly but is also readable
        text_types <- c("application/json",
            "application/x-www-form-urlencoded", "application/xml",
            "text/csv", "text/html", "text/plain",
            "text/tab-separated-values", "text/xml")
        is_text <- length(ct) && any(unlist(strsplit(ct, "; ")) %in% text_types)
        ## strsplit on ; because "charset" may be appended
        if (is_text) {
            ## Squelch the "No encoding supplied: defaulting to UTF-8."
            cont <- suppressMessages(content(response, "text"))
            response$content <- substitute(charToRaw(cont))
        } else if (inherits(response$request$output, "write_disk")) {
            ## Copy real file and substitute the response$content "path".
            ## Note that if content is a text type, the above attempts to
            ## make the mock file readable call `content()`, which reads
            ## in the file that has been written to disk, so it effectively
            ## negates the "download" behavior for the recorded response.
            downloaded_file <- paste0(filename, "-FILE")
            file.copy(response$content, downloaded_file)
            response$content <- structure(downloaded_file, class="path")
        }
        dput(response, file=filename)
    }
    return(filename)
}

#' @rdname capture_requests
#' @export
stop_capturing <- function () {
    for (verb in c("GET", "PUT", "POST", "PATCH", "DELETE", "VERB")) {
        safe_untrace(verb, add_headers)
    }
}
