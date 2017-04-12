#' Collect API Responses as Mock Files
#'
#' This context collects the responses from requests you make and stores them as
#' mock files. This enables you to perform a series of requests against a live
#' server once and then build your test suite using those mocks, running your
#' tests in \code{with_mock_API}.
#'
#' @param expr Code to run inside the context
#' @param path Where to save the mock files. Default is the current working
#' directory.
#' @return The result of \code{expr}
#' @examples
#' \dontrun{
#' capture_requests({
#'     GET("http://httpbin.org/get")
#'     GET("http://httpbin.org")
#'     GET("http://httpbin.org/response-headers",
#'         query=list(`Content-Type`="application/json"))
#'     utils::download.file("http://httpbin.org/gzip", tempfile())
#' })
#' }
#' @export
capture_requests <- function (expr, path=".") {
    ## Use "substitute" so that "path" gets inserted. Code remains quoted.
    req_tracer <- substitute({
        f <- file.path(path, buildMockURL(req))
        dir.create(dirname(f), showWarnings=FALSE, recursive=TRUE)
        .resp <- structure(list(content=resp$content, headers=headers),
            class="response")
        ## TODO: switch behavior based on request method, content type, and
        ## option to deparse the whole response object?
        cat(content(.resp, "text"), file=f)
    }, list(path=path))
    dl_tracer <- substitute({
        if (status == 0) {
            ## Only do this if the download was successful
            f <- file.path(path, buildMockURL(url, method="DOWNLOAD"))
            dir.create(dirname(f), showWarnings=FALSE, recursive=TRUE)
            file.copy(destfile, f)
        }
    }, list(path=path))
    env <- parent.frame()
    with_trace("request_perform", exit=req_tracer, where=add_headers, expr={
        with_trace("download.file", exit=dl_tracer, where=modifyList, expr={
            eval(expr, env)
        })
    })
}
