#' Return something that looks enough like an httr 'response'
#'
#' These functions allow mocking of HTTP requests without requiring an internet
#' connection or server to run against. Their return shape is a 'httr'
#' "response" class object that should behave like a real response generated
#' by a real request.
#'
#' These mock functions can be used to replace the 'httr' verb functions using
#' the 'testthat' package's \code{\link[testthat]{with_mock}} function. See the
#' test suite for this package for an illustration of how to use them.
#' @param url A character URL for the request. For \code{fakeDownload}, this
#' should be a path to a file that exists.
#' @param verb Character name for the HTTP verb. Default is "GET"
#' @param status_code Integer HTTP response status
#' @param headers Optional list of additional response headers to return
#' @param content If supplied, a JSON-serializable list that will be returned
#' as response content with Content-Type: application/json. If no \code{content}
#' is provided, and if the \code{status_code} is not 204 No Content, the
#' \code{url} will be set as the response content with Content-Type: text/plain.
#' @param query For \code{fakeGET}, optional query parameters in the request, as
#' a list (as \code{GET} expects). If supplied, the \code{query} will be set
#' as the fake \code{content}.
#' @param body For the other fake verbs, a request payload. If provided, it will
#' be set as the response \code{content}.
#' @param destfile For \code{fakeDownload}, character file path to "download"
#' to. \code{fakeDownload} will copy the file at \code{url} to this path.
#' @param ... Additional arguments to the real functions, ignored by the mocks.
#' @return The fake verbs return a 'httr' response class object.
#' \code{fakeDownload} returns 0, the success code returned by
#' \code{\link[utils]{download.file}}.
#' @export
#' @importFrom jsonlite toJSON
#' @importFrom utils modifyList
fakeResponse <- function (url="", verb="GET", status_code=200, headers=list(), content=NULL) {
    ## Return something that looks enough like an httr 'response'
    base.headers <- list()
    if (is.null(content)) {
        if (status_code != 204) {
            ## Echo back the URL as the content
            content <- url
            base.headers <- list(`Content-Type`="text/plain")
        }
    } else {
        ## We have content supplied, so JSON it
        content <- toJSON(content, auto_unbox=TRUE, null="null", na="null",
            force=TRUE)
        base.headers <- list(`Content-Type`="application/json")
    }
    if (!is.null(content)) {
        base.headers[["content-length"]] <- nchar(content)
        content <- charToRaw(content)
    }

    structure(list(
        url=url,
        status_code=status_code,
        times=structure(c(rep(0, 5), nchar(url)),
            .Names=c("redirect", "namelookup", "connect", "pretransfer",
                    "starttransfer", "total")),
        request=list(method=verb, url=url),
        headers=modifyList(base.headers, headers),
        content=content
    ), class="response")
}

#' @rdname fakeResponse
#' @export
fakeGET <- function (url, query=NULL, ...) {
    fakeResponse(url, content=query)
}

#' @rdname fakeResponse
#' @export
fakePUT <- function (url, body=NULL, ...) {
    message("PUT ", url, " ", body)
    return(fakeResponse(url, verb="PUT", status_code=204))
}

#' @rdname fakeResponse
#' @export
fakePATCH <- function (url, body=NULL, ...) {
    message("PATCH ", url, " ", body)
    return(fakeResponse(url, verb="PATCH", status_code=204))
}

#' @rdname fakeResponse
#' @export
fakePOST <- function (url, body=NULL, ...) {
    message("POST ", url, " ", body)
    return(fakeResponse(url, verb="POST", status_code=201, content=body))
}

#' @rdname fakeResponse
#' @export
fakeDELETE <- function (url, body=NULL, ...) {
    message("DELETE ", url, " ", body)
    return(fakeResponse(url, verb="DELETE", status_code=204))
}

#' @rdname fakeResponse
#' @export
fakeDownload <- function (url, destfile, ...) {
    file.copy(url, destfile)
    return(0)
}
