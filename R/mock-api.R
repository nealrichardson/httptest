#' Serve a mock API from files
#'
#' In this context, HTTP GET requests attempt to read from files. This allows
#' test code to use API fixtures and to proceed evaluating code that expects
#' HTTP requests to return meaningful responses. Other HTTP request methods, as
#' well as GET requests that do not correspond to a file that exist, raise
#' errors, like how code{\link{without_internet}} does.
#'
#' File paths for API fixture files may be relative to the 'tests/testthat'
#' directory, i.e. relative to the .R test files themselves.
#'
#' Some file path matching rules: first, in order to emulate an HTTP API, in
#' which, unlike a file system, a "directory" itself is a resource, all mock
#' '"URLs" should end in "/", and mock files themselves should end in ".json"
#' '(for in the current version of this package,
#' all API responses are assumed to be Content-Type: application/json). That is,
#' a mocked \code{GET("api/")} will read a "api.json" file, while
#' \code{GET("api/object1/")} reads "api/object1.json". If the request URL
#' contains a query string, it will be popped off, hashed
#' by \code{\link[digest]{digest}}, and the first six characters appended to the
#' file being read. For example, \code{GET("api/object1/?a=1")} reads
#' "api/object1-b64371.json"
#' @param expr Code to run inside the fake context
#' @return The result of \code{expr}
#' @export
with_mock_API <- function (expr) {
    with_mock(
        `httr:::request_perform`=mockRequest,
        `utils::download.file`=mockDownload,
        eval.parent(expr)
    )
}

mockRequest <- function (req, handle, refresh) {
    f <- buildMockURL(req$url)
    if (req$method == "GET" && file.exists(f)) {
        return(fakeResponse(req$url, req$method,
            content=readBin(f, "raw", 4096), ## Assumes mock is under 4K
            status_code=200, headers=list(`Content-Type`="application/json")))
            ## TODO: don't assume content-type
    } else {
        if (req$method == "GET") {
            ## For ease of debugging if a file isn't found
            req$url <- paste0(req$url, " (", f, ")")
        }
        return(stopRequest(req))
    }
}

#' Convert a mock "URL" to a file path
#'
#' Because HTTP allows "directories" to be resources themselves but the local
#' file system does not, this function disambiguates those cases. Use
#' HTTP-looking mock URLs in your fixtures, and this function lets you have both
#' "api/" and "api/object1/" exist as files.
#'
#' This function also handles query parameters, as described in
#' \link{with_mock_API}.
#'
#' This function is exported so that other packages can construct similar mock
#' behaviors or override specific requests at a higher level than
#' \code{with_mock_API} mocks.
#' @param url character "URL" to convert
#' @param method character HTTP method. Currently ignored.
#' @return A file path and name, with .json extension. The file may or may not
#' exist: existence is not a concern of this function.
#' @importFrom digest digest
#' @export
buildMockURL <- function (url, method="GET") {
    ## Handle query params
    parts <- unlist(strsplit(url, "?", fixed=TRUE))
    f <- sub("\\/$", "", parts[1])
    if (length(parts) > 1) {
        ## If there's a query, then req$url has been through build_url(parse_url())
        ## so it has grown a ":///" prefix. Prune that, and append the digest
        ## suffix
        f <- paste0(
            sub("^:///", "", f),
            "-",
            substr(digest(parts[2]), 1, 6)
        )
    }

    ## TODO: Allow other HTTP verbs

    ## Add file extension
    f <- paste0(f, ".json")  ## TODO: don't assume content-type
    return(f)
}

mockDownload <- function (url, destfile, ...) {
    if (file.exists(url)) {
        file.copy(url, destfile)
        return(0)
    } else {
        stopDownload(url)
    }
}
