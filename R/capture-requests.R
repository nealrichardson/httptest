#' Collect API Responses as Mock Files
#'
#' `capture_requests` is a context that collects the responses from requests
#' you make and stores them as mock files. This enables you to perform a series
#' of requests against a live server once and then build your test suite using
#' those mocks, running your tests in [with_mock_API()].
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
#' response objects. It should take a `response`-class object as its argument
#' and should return a cleansed `response` object. This allows you to remove
#' certain request and response contents, such as authentication tokens, from
#' the mocks that get written out. See [redact_auth()], the default, for more
#' details.
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
capture_requests <- function (expr, path=.mockPaths()[1], simplify=TRUE,
                              verbose=FALSE, redact=redact_auth) {
    start_capturing(path, simplify, verbose, redact)
    on.exit(stop_capturing())
    eval.parent(expr)
}

#' @rdname capture_requests
#' @export
start_capturing <- function (path=.mockPaths()[1], simplify=TRUE, verbose=FALSE,
                             redact=redact_auth) {
    ## Use "substitute" so that "path" gets inserted. Code remains quoted.
    req_tracer <- substitute({
        ## Get the value returned from the function, and sanitize it
        .resp <- redact(returnValue())
        ## Omit curl handle C pointer
        .resp$handle <- NULL

        ## Construct the mock file path
        f <- file.path(path, buildMockURL(.resp$request))
        dir.create(dirname(f), showWarnings=FALSE, recursive=TRUE)

        ## Get the Content-Type
        ct <- unlist(.resp$headers[tolower(names(.resp$headers)) == "content-type"])
        is_json <- any(grepl("application/json", ct))
        if (simplify && .resp$status_code == 200 && is_json) {
            ## Squelch the "No encoding supplied: defaulting to UTF-8."
            ## TODO: support other text content-types than JSON
            cat(suppressMessages(content(.resp, "text")), file=f)
        } else {
            ## Dump an object that can be sourced

            ## Change the file extension to .R
            f <- sub("json$", "R", f)

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
                cont <- suppressMessages(content(.resp, "text"))
                .resp$content <- substitute(charToRaw(cont))
            } else if (inherits(.resp$request$output, "write_disk")) {
                ## Copy real file and substitute the response$content "path".
                ## Note that if content is a text type, the above attempts to
                ## make the mock file readable call `content()`, which reads
                ## in the file that has been written to disk, so it effectively
                ## negates the "download" behavior for the recorded response.
                downloaded_file <- paste0(f, "-FILE")
                file.copy(.resp$content, downloaded_file)
                .resp$content <- structure(downloaded_file, class="path")
            }
            dput(.resp, file=f)
        }
        if (verbose) message("Writing ", normalizePath(f))
    }, list(path=path, simplify=simplify, verbose=verbose, redact=redact))
    suppressMessages(trace("request_perform", exit=req_tracer, where=add_headers,
        print=FALSE))
    invisible(path)
}

#' @rdname capture_requests
#' @export
stop_capturing <- function () {
    suppressMessages(untrace("request_perform", where=add_headers))
}
