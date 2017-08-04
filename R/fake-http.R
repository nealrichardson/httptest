#' Make all HTTP requests return a fake 'response' object
#'
#' In this context, HTTP verb functions raise a 'message' so that test code can
#' assert that the requests are made. As in [without_internet()], the message
#' raised has a well-defined shape, made of three
#' elements, separated by space: (1) the request
#' method (e.g. "GET", or for downloading, "DOWNLOAD"); (2) the request URL; and
#' (3) the request body, if present. The verb-expectation functions,
#' such as `expect_GET` and `expect_POST`, look for this shape.
#'
#' Unlike `without_internet`,
#' the HTTP functions do not error and halt execution, instead returning a
#' `response`-class object so that code calling the HTTP functions can
#' proceed with its response handling logic and itself be tested. The response
#' it returns echoes back most of the request itself, similar to how some
#' endpoints on \url{http://httpbin.org} do.
#' @param expr Code to run inside the fake context
#' @return The result of `expr`
#' @examples
#' with_fake_HTTP({
#'     expect_GET(req1 <- httr::GET("http://example.com"), "http://example.com")
#'     req1$url
#'     expect_POST(req2 <- httr::POST("http://example.com", body='{"a":1}'),
#'         "http://example.com")
#'     httr::content(req2)
#' })
#' @export
#' @importFrom testthat expect_message
with_fake_HTTP <- function (expr) {
    with_mock(
        `httr:::request_perform`=fakeRequest,
        `httptest::request_happened`=expect_message,
        `utils::download.file`=fakeDownload,
        eval.parent(expr)
    )
}

#' Return something that looks enough like an httr 'response'
#'
#' These functions allow mocking of HTTP requests without requiring an internet
#' connection or server to run against. Their return shape is a 'httr'
#' "response" class object that should behave like a real response generated
#' by a real request.
#'
#' @param url A character URL for the request. For `fakeDownload`, this
#' should be a path to a file that exists.
#' @param verb Character name for the HTTP verb. Default is "GET"
#' @param status_code Integer HTTP response status
#' @param headers Optional list of additional response headers to return
#' @param content If supplied, a JSON-serializable list that will be returned
#' as response content with Content-Type: application/json. If no `content`
#' is provided, and if the `status_code` is not 204 No Content, the
#' `url` will be set as the response content with Content-Type: text/plain.
#' @param destfile For `fakeDownload`, character file path to "download"
#' to. `fakeDownload` will copy the file at `url` to this path.
#' @param ... Additional arguments for `fakeDownload`
#' @return The fake verbs return a 'httr' response class object.
#' `fakeDownload` returns 0, the success code returned by
#' [utils::download.file()].
#' @export
#' @importFrom jsonlite toJSON
#' @importFrom utils modifyList
fakeResponse <- function (url="", verb="GET", status_code=200, headers=list(), content=NULL) {
    base.headers <- list()
    if (status_code == 204) {
        content <- NULL
    } else if (!is.raw(content)) {
        if (!is.character(content)) {
            ## JSON it
            content <- toJSON(content, auto_unbox=TRUE, null="null", na="null",
                force=TRUE)
            base.headers <- list(`Content-Type`="application/json")
        }
        base.headers[["content-length"]] <- nchar(content)
        content <- charToRaw(content)
    }
    headers <- modifyList(base.headers, headers)

    structure(list(
        url=url,
        status_code=status_code,
        times=structure(c(rep(0, 5), nchar(url)),
            .Names=c("redirect", "namelookup", "connect", "pretransfer",
                    "starttransfer", "total")),
        request=list(method=verb, url=url),
        headers=headers,

        content=content
    ), class="response")
}

#' @rdname fakeResponse
#' @export
fakeDownload <- function (url, destfile, ...) {
    message("DOWNLOAD ", url)
    writeLines(url, destfile)
    return(0)
}

fakeRequest <- function (req, handle, refresh) {
    out <- paste(req$method, req$url)
    body <- requestBody(req)
    headers <- list(`Content-Type`="application/json") ## TODO: don't assume content-type
    status_code <- ifelse(is.null(body) && req$method != "GET", 204, 200)
    if (!is.null(body)) {
        out <- paste(out, body)
    }
    message(out)
    return(fakeResponse(req$url, req$method, content=body,
        status_code=status_code, headers=headers))
}
