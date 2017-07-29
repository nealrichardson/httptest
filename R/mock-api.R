#' Serve a mock API from files
#'
#' In this context, HTTP requests attempt to load API response fixtures from
#' files. This allows test code to proceed evaluating code that expects
#' HTTP requests to return meaningful responses. Requests that do not have a
#' corresponding fixture file raise errors, like how [without_internet()]
#' does.
#'
#' Requests are translated to mock file paths according to several rules that
#' incorporate the request method, URL, query parameters, and body. See
#' [buildMockURL()] for details.
#'
#' File paths for API fixture files may be relative to the 'tests/testthat'
#' directory, i.e. relative to the .R test files themselves. This is the default
#' location for storing and retrieving mocks, but you can put them anywhere you
#' want as long as you set the appropriate location with [.mockPaths()].
#'
#' @param expr Code to run inside the fake context
#' @return The result of `expr`
#' @seealso [buildMockURL()] [.mockPaths()]
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
    mockfile <- findMockFile(f)
    if (!is.null(mockfile)) {
        if (grepl("\\.R$", mockfile)) {
            ## It's a full "response". Source it.
            return(source(mockfile)$value)
        } else {
            ## TODO: don't assume content-type
            headers <- list(`Content-Type`="application/json")
            cont <- readBin(mockfile, "raw", 4096*32)
            ## Assumes mock is under 128K       ^
            resp <- fakeResponse(req$url, req$method, content=cont,
                status_code=200L, headers=headers)
            return(resp)
        }
    }
    ## Else: fail.
    ## For ease of debugging if a file isn't found, include it in the
    ## error that gets printed.
    req$mockfile <- f
    return(stopRequest(req))
}

#' Convert a request to a mock file path
#'
#' Requests are translated to mock file paths according to several rules that
#' incorporate the request method, URL, query parameters, and body.
#'
#' First, the URL is modified in two ways in order to allow it to map to a
#' local file system. All mock files have the request protocol such as "http://"
#' removed from the URL, and they also have a file extension appended. In an
#' HTTP API, a "directory" itself is a resource,
#' so the extension allows distinguishing directories and files in the file
#' system. That is, a mocked `GET("http://example.com/api/")` may read a
#' "example.com/api.json" file, while
#' `GET("http://example.com/api/object1/")` reads "example.com/api/object1.json".
#'
#' The extension also gives information on content type. Two extensions are
#' currently supported: (1) .json and (2) .R. JSON mocks can be stored in .json
#' files, and when they are loaded by [with_mock_API()], relevant request
#' metadata (headers, status code, etc.) are inferred. If your API doesn't
#' return JSON, or if you want to simulate requests with other behavior (201
#' Location response, or 400 Bad Request, for example), you can store full
#' `response` objects in .R files that `with_mock_API` will `source` to load.
#' Any request can be stored as a .R mock, but the .json mocks offer a
#' simplified, more readable alternative. ([capture_requests()] will record
#' simplified .json files where appropriate and .R mocks otherwise by default.)
#'
#' Second, if the request URL contains a query string, it will be popped off,
#' hashed by [digest::digest()], and the first six characters appended to the
#' file being read. For example, `GET("api/object1/?a=1")` reads
#' "api/object1-b64371.json". Third, request bodies are similarly hashed and
#' appended. Finally, if a request method other than GET is used it will be
#' appended to the end of the end of the file name. For example,
#' `POST("api/object1/?a=1")` reads "api/object1-b64371-POST.json".
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
#' @seealso [with_mock_API()] [capture_requests()]
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
    ## Sanitize the path to be portable for all R platforms
    f <- gsub(":", "-", f)
    if (length(parts) > 1) {
        ## There's a query string. Append the digest as a suffix.
        f <- paste0(f, "-", hash(parts[2]))
    }

    ## Handle body and append its hash if present
    if (!is.null(body)) {
        f <- paste0(f, "-", hash(body))
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

findMockFile <- function (file) {
    ## Go through .mockPaths() to find the local mockfile location.
    ## Return NULL if none found.
    for (path in .mockPaths()) {
        mockfile <- file.path(path, file)
        if (file.exists(mockfile)) {
            return(mockfile)
        }
        ## Else, see if there is a .R file "response" with the same path
        ## TODO: don't assume content-type
        mockfile <- sub("\\.json$", ".R", mockfile)
        if (file.exists(mockfile)) {
            return(mockfile)
        }
    }
    return(NULL)
}

requestBody <- function (req) {
    b <- req$options$postfields
    if (length(b) > 0) {
        ## Check length this way because b may be NULL or length 0 raw vector
        b <- rawToChar(b)
    } else {
        b <- req$fields
        if (!is.null(b)) {
            ## Get a readable string representation
            b <- deparse(b, control=NULL)
            ## Strip out unhelpful indentation that it may add, then collapse
            ## to single string, if broken into multiple lines
            b <- paste(sub("^ +", "", b), collapse="")
        }
    }
    return(b)
}

hash <- function (string, n=6) substr(digest(string), 1, n)

mockDownload <- function (url, destfile, ...) {
    f <- findMockFile(buildMockURL(url, method="DOWNLOAD"))
    if (!is.null(f)) {
        file.copy(f, destfile)
        status <- 0
        return(status)
    } else {
        stopDownload(url)
    }
}
