#' Make all HTTP requests return a fake response
#'
#' In this context, HTTP verb functions raise a 'message' so that test code can
#' assert that the requests are made. As in [without_internet()], the message
#' raised has a well-defined shape, made of three
#' elements, separated by space: (1) the request
#' method (e.g. "GET" or "POST"); (2) the request URL; and
#' (3) the request body, if present. The verb-expectation functions,
#' such as `expect_GET` and `expect_POST`, look for this shape.
#'
#' Unlike `without_internet`,
#' the HTTP functions do not error and halt execution, instead returning a
#' `response`-class object so that code calling the HTTP functions can
#' proceed with its response handling logic and itself be tested. The response
#' it returns echoes back most of the request itself, similar to how some
#' endpoints on \url{http://httpbin.org} do.
#'
#' @param expr Code to run inside the fake context
#' @return The result of `expr`
#' @examples
#' with_fake_http({
#'   expect_GET(req1 <- httr::GET("http://example.com"), "http://example.com")
#'   req1$url
#'   expect_POST(
#'     req2 <- httr::POST("http://example.com", body = '{"a":1}'),
#'     "http://example.com"
#'   )
#'   httr::content(req2)
#' })
#' @export
#' @importFrom testthat expect_message
with_fake_http <- function(expr) {
  old <- options(..httptest.request.errors = FALSE)
  mock_perform(fake_request)
  on.exit({
    do.call(options, old)
    stop_mocking()
  })
  eval.parent(expr)
}

#' Return something that looks like a 'response'
#'
#' These functions allow mocking of HTTP requests without requiring an internet
#' connection or server to run against. Their return shape is a 'httr'
#' "response" class object that should behave like a real response generated
#' by a real request.
#'
#' @param request An 'httr' `request`-class object. A character URL is also
#' accepted, for which a fake request object will be created, using the `verb`
#' argument as well.
#' @param verb Character name for the HTTP verb, if `request` is a URL. Default
#' is "GET".
#' @param status_code Integer HTTP response status
#' @param headers Optional list of additional response headers to return
#' @param content If supplied, a JSON-serializable list that will be returned
#' as response content with Content-Type: application/json. If no `content`
#' is provided, and if the `status_code` is not 204 No Content, the
#' `url` will be set as the response content with Content-Type: text/plain.
#' @return An 'httr' response class object.
#' @export
#' @importFrom jsonlite toJSON
#' @importFrom utils modifyList
fake_response <- function(request,
                          verb = "GET",
                          status_code = 200,
                          headers = list(),
                          content = NULL) {
  if (is.character(request)) {
    # To-be-deprecated(?) behavior of passing in a URL. Fake a request.
    request <- structure(list(method = verb, url = request), class = "request")
  }
  # TODO: if the request says `write_disk`, should we copy the mock file to
  # that location, so that that file exists?
  base.headers <- list()
  if (status_code == 204) {
    content <- NULL
  } else if (!is.raw(content)) {
    if (!is.character(content)) {
      # JSON it
      content <- toJSON(content,
        auto_unbox = TRUE, null = "null", na = "null",
        force = TRUE
      )
      base.headers <- list(`Content-Type` = "application/json")
    }
    base.headers[["content-length"]] <- nchar(content)
    content <- charToRaw(content)
  }
  headers <- modifyList(base.headers, headers)

  structure(list(
    url = request$url,
    status_code = status_code,
    times = structure(c(rep(0, 5), nchar(request$url)),
      .Names = c(
        "redirect", "namelookup", "connect", "pretransfer",
        "starttransfer", "total"
      )
    ),
    request = request,
    headers = headers,
    content = content
  ), class = "response")
}

fake_request <- function(req, handle, refresh) {
  out <- paste(req$method, req$url)
  body <- request_body(req)
  headers <- list(`Content-Type` = "application/json")
  status_code <- ifelse(is.null(body) && req$method != "GET", 204, 200)
  if (!is.null(body)) {
    out <- paste(out, body)
  }
  message(out)
  return(fake_response(req,
    content = body, status_code = status_code,
    headers = headers
  ))
}
