#' Serve a mock API from files
#'
#' In this context, HTTP requests attempt to load API response fixtures from
#' files. This allows test code to proceed evaluating code that expects
#' HTTP requests to return meaningful responses. Requests that do not have a
#' corresponding to a fixture file raise
#' errors, like how [without_internet()] does.
#'
#' File paths for API fixture files may be relative to the 'tests/testthat'
#' directory, i.e. relative to the .R test files themselves.
#'
#' Some file path matching rules: first, in order to emulate an HTTP API, in
#' which, unlike a file system, a "directory" itself is a resource, all mock
#' "URLs" should end in "/", and mock files themselves should end in ".json"
#' (for in the current version of this package,
#' all API responses are assumed to be Content-Type: application/json). That is,
#' a mocked `GET("api/")` will read a "api.json" file, while
#' `GET("api/object1/")` reads "api/object1.json". If the request URL
#' contains a query string, it will be popped off, hashed
#' by [digest::digest()], and the first six characters appended to the
#' file being read. For example, `GET("api/object1/?a=1")` reads
#' "api/object1-b64371.json". Request bodies are similarly hashed and appended.
#' If method other than GET is used it will be appended to the end of the end of
#' the file name. For example, `POST("api/object1/?a=1")` reads
#' "api/object1-b64371-POST.json".
#'
#' @param expr Code to run inside the fake context
#' @return The result of `expr`
#' @export
with_mock_API <- function (expr) {
    with_mock(
        `httr:::request_perform`=mockRequest,
        `utils::download.file`=mockDownload,
        eval.parent(expr)
    )
}

mockRequest <- function (req, handle, refresh) {
    ## If there's a query, then req$url has been through build_url(parse_url())
    ## and if it's a file and not URL, it has grown a ":///" prefix. Prune that.
    req$url <- sub("^:///", "", req$url)
    f <- buildMockURL(req)
    if (file.exists(f)) {
        headers <- list(`Content-Type`="application/json")
        resp <- fakeResponse(req$url, req$method,
            content=readBin(f, "raw", 4096*32), ## Assumes mock is under 128K
            status_code=200, headers=headers)
        return(resp)
            ## TODO: don't assume content-type
    } else {
        ## For ease of debugging if a file isn't found, include it in the
        ## error that gets printed.
        req$mockfile <- f
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
#' [with_mock_API]().
#'
#' This function is exported so that other packages can construct similar mock
#' behaviors or override specific requests at a higher level than
#' `with_mock_API` mocks.
#' @param req A `request` object, or a character "URL" to convert
#' @param method character HTTP method. If `req` is a 'request' object,
#' its request method will override this argument
#' @return A file path and name, with .json extension. The file may or may not
#' exist: existence is not a concern of this function.
#' @importFrom digest digest
#' @export
buildMockURL <- function (req, method="GET") {
    if (is.character(req)) {
        ## A URL/file download
        url <- req
        body <- NULL
    } else {
        url <- req$url
        method <- req$method
        body <- requestBody(req)
    }

    ## Remove protocol
    url <- sub("^.*?://", "", url)
    ## Handle query params
    parts <- unlist(strsplit(url, "?", fixed=TRUE))
    ## Remove trailing slash
    f <- sub("\\/$", "", parts[1])
    if (length(parts) > 1) {
        ## Append the digest suffix
        f <- paste0(f, "-", hash(parts[2]))
    }

    ## Handle body
    if (length(body) > 0) {
        f <- paste0(f, "-", hash(rawToChar(body)))
    }

    if (method == "DOWNLOAD") {
        ## Don't append anything further.
        return(f)
    } else if (method != "GET") {
        ## Append method to the file name for non GET requests
        f <- paste0(f, "-", method)
    }

    ## Add file extension
    f <- paste0(f, ".json")  ## TODO: don't assume content-type
    return(f)
}

requestBody <- function (req) req$options$postfields

hash <- function (string, n=6) substr(digest(string), 1, n)

mockDownload <- function (url, destfile, ...) {
    f <- buildMockURL(url, method="DOWNLOAD")
    if (file.exists(f)) {
        file.copy(f, destfile)
        status <- 0
        return(status)
    } else {
        stopDownload(url)
    }
}
