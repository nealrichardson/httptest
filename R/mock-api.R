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
#' [build_mock_url()] for details.
#'
#' File paths for API fixture files may be relative to the 'tests/testthat'
#' directory, i.e. relative to the .R test files themselves. This is the default
#' location for storing and retrieving mocks, but you can put them anywhere you
#' want as long as you set the appropriate location with [.mockPaths()].
#'
#' In the interest of standardizing naming conventions, `with_mock_api()` is the
#' preferred name for this context; `with_mock_API()` is being deprecated.
#'
#' @param expr Code to run inside the fake context
#' @return The result of `expr`
#' @seealso [use_mock_api()] to enable mocking on its own (not in a context); [build_mock_url()]; [.mockPaths()]
#' @export
with_mock_api <- function (expr) {
    use_mock_api()
    on.exit(stop_mocking())
    eval.parent(expr)
}

#' @rdname with_mock_api
#' @export
with_mock_API <- with_mock_api

#' Turn on API mocking
#'
#' This function intercepts HTTP requests made through `httr` and serves mock
#' file responses instead. It is what [with_mock_api()] does, minus the
#' automatic disabling of mocking when the context finishes.
#'
#' Note that you in order to resume normal request behavior, you will need to
#' call [stop_mocking()] yourself---this function does not clean up after itself
#' as 'with_mock_api` does.
#' @return Nothing; called for its side effects.
#' @seealso [with_mock_api()] [stop_mocking()] [block_requests()]
#' @export
use_mock_api <- function () mock_perform(mock_request)

mock_request <- function (req, handle, refresh) {
    ## If there's a query, then req$url has been through build_url(parse_url())
    ## and if it's a file and not URL, it has grown a ":///" prefix. Prune that.
    req$url <- sub("^:///", "", req$url)
    f <- buildMockURL(get_current_requester()(req))
    mockfile <- find_mock_file(f)
    if (!is.null(mockfile)) {
        if (grepl("\\.R$", mockfile)) {
            ## It's a full "response". Source it.
            return(source(mockfile)$value)
        } else {
            ## TODO: don't assume content-type
            headers <- list(`Content-Type`="application/json")
            cont <- readBin(mockfile, "raw", n=file.size(mockfile))
            resp <- fake_response(req, content=cont, status_code=200L,
                headers=headers)
            return(resp)
        }
    }
    ## Else: fail.
    ## For ease of debugging if a file isn't found, include it in the
    ## error that gets printed.
    req$mockfile <- f
    return(stop_request(req))
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
#' files, and when they are loaded by [with_mock_api()], relevant request
#' metadata (headers, status code, etc.) are inferred. If your API doesn't
#' return JSON, or if you want to simulate requests with other behavior (201
#' Location response, or 400 Bad Request, for example), you can store full
#' `response` objects in .R files that `with_mock_api` will `source` to load.
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
#' `with_mock_api` mocks.
#'
#' In the interest of standardizing naming conventions, `build_mock_url()` is
#' the preferred name for this context; `buildMockURL()` is being deprecated.
#'
#' @param req A `request` object, or a character "URL" to convert
#' @param method character HTTP method. If `req` is a 'request' object,
#' its request method will override this argument
#' @return A file path and name, with .json extension. The file may or may not
#' exist: existence is not a concern of this function.
#' @importFrom digest digest
#' @seealso [with_mock_api()] [capture_requests()]
#' @export
build_mock_url <- function (req, method="GET") {
    if (is.character(req)) {
        ## A URL/file download
        url <- req
        body <- NULL
    } else {
        url <- req$url
        method <- req$method
        body <- request_body(req)
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

    if (method != "GET") {
        ## Append method to the file name for non GET requests
        f <- paste0(f, "-", method)
    }

    ## Add file extension
    f <- paste0(f, ".json")  ## TODO: don't assume content-type
    return(f)
}

#' @rdname build_mock_url
#' @export
buildMockURL <- build_mock_url

#' Go through mock paths to find the local mock file location
#'
#' @param file A file path, as generated by [build_mock_url()].
#' @return A path to a file that exists, or `NULL` if none found.
#' @keywords internal
#' @export
find_mock_file <- function (file) {
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

## TODO: remove
findMockFile <- find_mock_file

request_body <- function (req) {
    ## request_body returns a string if the request has a body, NULL otherwise
    b <- request_postfields(req)
    if (is.null(b)) {
        b <- req$fields
        if (!is.null(b)) {
            ## Get a readable string representation
            b <- deparse(b, control=deparseNamedList())
            ## Strip out unhelpful indentation that it may add, then collapse
            ## to single string, if broken into multiple lines
            b <- paste(sub("^ +", "", b), collapse="")
        }
    }
    return(b)
}

request_postfields <- function (req) {
    b <- req[["options"]][["postfields"]]
    if (length(b) > 0) {
        ## Check length this way because b may be NULL or length 0 raw vector
        return(rawToChar(b))
    } else {
        return(NULL)
    }
}

deparseNamedList <- function () {
    ## r73699 2017-11-09
    ## (https://github.com/wch/r-source/commit/62fced00949b9a261034d24789175b205f7fa866)
    ## adds a "niceNames" deparse option, which is now required to get named
    ## lists printed with names (they no longer are named with `control=NULL`).
    ## As it turns out, you can't specify "niceNames" prophalactically---it
    ## errors on older versions of R that don't support it. So this function
    ## standardizes the behavior across R versions.
    ##
    ## R 3.4 has the old behavior. The new behavior will appear in R 3.5.
    past <- inherits(try(.deparseOpts("niceNames"), silent=TRUE), "try-error")
    past <- ifelse(past, "old", "new")
    return(list(new="niceNames")[[past]])
}

hash <- function (string, n=6) substr(digest(string), 1, n)
