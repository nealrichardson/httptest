# httptest: A Test Environment for HTTP Requests in R

[![Build Status](https://travis-ci.org/nealrichardson/httptest.png?branch=master)](https://travis-ci.org/nealrichardson/httptest) [![Build status](https://ci.appveyor.com/api/projects/status/egrw65593iso21cu?svg=true)](https://ci.appveyor.com/project/nealrichardson/httptest) [![codecov](https://codecov.io/gh/nealrichardson/httptest/branch/master/graph/badge.svg)](https://codecov.io/gh/nealrichardson/httptest)

Testing code and packages that communicate with remote servers can be painful. Dealing with authentication, bootstrapping server state, cleaning up objects that may get created during the test run, network flakiness, and other complications can make testing seem too costly to bother with. But it doesn't need to be that hard. The `httptest` package enables one to test all of the logic on the R sides of the API in your package without requiring access to the remote service. Importantly, `httptest` provides three test **contexts** that mock the network connection in different ways, and it offers additional **expectations** to assert that HTTP requests were--or were not--made. Using these tools, one can test that code is making the intended requests and that it handles the expected responses correctly, all without depending on a connection to a remote API.

This package bridges the gap between two others: (1) [testthat](https://github.com/hadley/testthat), which provides a useful framework for unit testing in R but doesn't come with tools for testing across web APIs; and (2) [httr](https://github.com/hadley/httr), which makes working with HTTP in R easy but doesn't make it simple to test the code that uses it.

## Installing

`httptest` can be installed from CRAN with

    install.packages("httptest")

The pre-release version of the package can be pulled from GitHub using the [devtools](https://github.com/hadley/devtools) package:

    # install.packages("devtools")
    devtools::install_github("nealrichardson/httptest")

## Using

Wherever you normally load `testthat`, load `httptest` instead. It "requires" `testthat`, so both will be loaded by using `httptest`. Specifically, you'll want to swap in `httptest` in:

* the DESCRIPTION file, where `testthat` is typically referenced under "Suggests"
* tests/testthat.R, which may otherwise begin with `library(testthat)`.

Then, you're ready to start using the tools that `httptest` provides. The section below outlines the package's main functions. See the test suite and help pages for usage examples.

When unit-testing code that communicates with another service, you need to make assertions about two different kinds of logic: (1) given some inputs, does my code make the correct request(s) to that service; and (2) does my code correctly handle the types of responses that that service can return? The contexts and expectation functions provided by this package help you to test both sides.

### Contexts

The package includes three test contexts, which you wrap around test code that would otherwise make network requests.

* **without_internet** converts HTTP requests made through either `httr` functions or the `download.file` function in the base `utils` package into errors that print the request method, URL, and body payload, if provided. This is useful for asserting that a function call would make a correctly-formed HTTP request, as well as for asserting that a function does not make a request (because if it did, it would raise an error in this context).
* **with_fake_HTTP** raises a "message" instead of an "error", and HTTP requests return a "response"-class object. Like `without_internet`, it allows you to assert that the correct requests were (or were not) made, but since it doesn't cause the code to exit with an error, you can test code in functions that comes after requests, provided that it doesn't expect a particular response to each request.
* **with_mock_API** lets you provide custom fixtures as responses to GET requests. It maps URLs, including query parameters, to files in your test directory, and it includes the file contents in the mocked "response" object. Request methods other than GET raise errors the same way that `without_internet` does. This context allows you to test more complex R code that makes GET requests and does something with the response, simulating how the API should respond to specific requests.

### Expectations

* **expect_GET**, **expect_PUT**, **expect_PATCH**, **expect_POST**, and **expect_DELETE** assert that the specified HTTP request is made within one of the test contexts. They catch the error or message raised by the mocked HTTP service and check that the request URL and optional body match the expectation. (Mocked responses in `with_mock_API` just proceed with their response content and don't trigger `expect_GET`, however.)
* **expect_no_request** is the inverse of those: it asserts that no error or message from a mocked HTTP service is raised.
* **expect_header** asserts that an HTTP request, mocked or not, contains a request header.
* **expect_json_equivalent** doesn't directly concern HTTP, but it is useful for working with JSON APIs. It checks that two R objects would generate equivalent JSON, taking into account how JSON objects are unordered whereas R named lists are ordered.

### Other tools

* **skip_if_disconnected** skips following tests if you don't have a working internet connection or can't reach a given URL. This is useful for preventing spurious failures when doing integration tests with a real API.
* **public** is another wrapper around test code that will cause tests to fail if they call functions that aren't "exported" in the package's namespace. Nothing HTTP specific about it, but it's something that I've found useful for preventing accidentally releasing a package without documenting and exporting new functions. While you can use "examples" in the man pages for ensuring that functions you're documenting are exported, code that communicates with remote APIs may not be easily set up to run in a help page example. This context allows you to make those assertions within your test suite.

## Contributing

Suggestions and pull requests are more than welcome. This package is pulled together from the test setup code I'd written and copied around among three different packages. While the code here has been well used and hashed out over a couple of years of working with them, I have naturally focused on features that have been helpful for working with specific APIs. The concepts provided here are generally useful, but some details for working with other APIs may be missing. In particular, the initial release of the package assumes "Content-Type: application/json" in several places.

## For developers

The repository includes a Makefile to facilitate some common tasks.

### Running tests

`$ make test`. You can also specify a specific test file or files to run by adding a "file=" argument, like `$ make test file=offline`. `test_package` will do a regular-expression pattern match within the file names. See its documentation in the `testthat` package.

### Updating documentation

`$ make doc`. Requires the [roxygen2](https://github.com/klutometis/roxygen) package.
