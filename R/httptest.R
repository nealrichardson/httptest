#' `httptest`: A Test Environment for HTTP Requests
#'
#' If \pkg{httr} makes HTTP easy and \pkg{testthat} makes testing fun,
#' \pkg{httptest} makes testing your code that uses HTTP a simple pleasure.
#'
#' The `httptest` package lets you test R code that wraps an API without
#' requiring access to the remote service. It provides three test **contexts**
#' that mock the network connection in different ways. [with_mock_API()] lets
#' you provide custom fixtures as responses to requests, stored as plain-text
#' files in your test directory. [without_internet()] converts HTTP requests
#' into errors that print the request method, URL, and body payload, if
#' provided, allowing you to assert that a function call would make a
#' correctly-formed HTTP request or assert that a function does not make a
#' request (because if it did, it would raise an error in this context).
#' [with_fake_HTTP()] raises a "message" instead of an "error", and HTTP
#' requests return a "response"-class object. Like `without_internet`, it allows
#' you to assert that the correct requests were (or were not) made, but it
#' doesn't cause the code to exit with an error.
#'
#' `httptest` offers additional **expectations** to assert that HTTP requests
#' were--or were not--made. [expect_GET()], [expect_PUT()], [expect_PATCH()],
#' [expect_POST()], and [expect_DELETE()] assert that the specified HTTP request
#' is made within one of the test contexts. They catch the error or message
#' raised by the mocked HTTP service and check that the request URL and optional
#' body match the expectation. [expect_no_request()] is the inverse of those: it
#' asserts that no error or message from a mocked HTTP service is raised.
#' [expect_header()] asserts that an HTTP request, mocked or not, contains a
#' request header. [expect_json_equivalent()] checks that two R objects would
#' generate equivalent JSON, taking into account how JSON objects are unordered
#' whereas R named lists are ordered.
#'
#' The package also includes [capture_requests()], a context that collects the
#' responses from requests you make and stores them as mock files. This enables
#' you to perform a series of requests against a live server once and then build
#' your test suite using those mocks, running your tests in `with_mock_API`.
#'
#' Using these tools, you can test that code is making the intended requests and
#' that it handles the expected responses correctly, all without depending on a
#' connection to a remote API during the test run.
#'
#' @name httptest
#' @docType package
NULL
