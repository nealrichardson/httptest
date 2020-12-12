#' Make all HTTP requests raise an error
#'
#' `without_internet` simulates the situation when any network request will
#' fail, as in when you are without an internet connection. Any HTTP request
#' through the verb functions in `httr` will raise an error.
#'
#' The error message raised has a well-defined shape, made of three
#' elements, separated by space: (1) the request
#' method (e.g. "GET"); (2) the request URL; and
#' (3) the request body, if present. The verb-expectation functions,
#' such as [expect_GET()] and [expect_POST()], look for this shape.
#' @param expr Code to run inside the mock context
#' @return The result of `expr`
#' @seealso [block_requests()] to enable mocking on its own (not in a context)
#' @examples
#' without_internet({
#'   expect_error(
#'     httr::GET("http://httpbin.org/get"),
#'     "GET http://httpbin.org/get"
#'   )
#'   expect_error(httr::PUT("http://httpbin.org/put",
#'     body = '{"a":1}'
#'   ),
#'   'PUT http://httpbin.org/put {"a":1}',
#'   fixed = TRUE
#'   )
#' })
#' @export
without_internet <- function(expr) {
  block_requests()
  on.exit(stop_mocking())
  eval.parent(expr)
}

#' Block HTTP requests
#'
#' This function intercepts HTTP requests made through `httr` and raises an
#' informative error instead. It is what [without_internet()] does, minus the
#' automatic disabling of mocking when the context finishes.
#'
#' Note that you in order to resume normal request behavior, you will need to
#' call [stop_mocking()] yourself---this function does not clean up after itself
#' as 'without_internet` does.
#' @return Nothing; called for its side effects.
#' @seealso [without_internet()] [stop_mocking()] [use_mock_api()]
#' @export
block_requests <- function() mock_perform(stop_request)

stop_request <- function(req, handle, refresh) {
  out <- paste(req$method, req$url)
  body <- request_body(req)
  if (!is.null(body)) {
    # Max print option for debugging large payloads
    body <- substr(body, 1, getOption("httptest.max.print", nchar(body)))
    out <- paste(out, body)
  }

  if (!is.null(req$mockfile)) {
    # Poked in here by mock_request for ease of debugging
    # Append it to the end.
    # TODO: remove .json if/when possible; there for backwards compat
    out <- paste0(out, " (", req$mockfile, ".json)")
  }
  stop(out, call. = FALSE)
}
