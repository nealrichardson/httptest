# httptest: A Test Environment for HTTP Requests in R

[![Build Status](https://travis-ci.org/nealrichardson/httptest.png?branch=master)](https://travis-ci.org/nealrichardson/httptest) [![Build status](https://ci.appveyor.com/api/projects/status/egrw65593iso21cu?svg=true)](https://ci.appveyor.com/project/nealrichardson/httptest) [![codecov](https://codecov.io/gh/nealrichardson/httptest/branch/master/graph/badge.svg)](https://codecov.io/gh/nealrichardson/httptest)
[![cran](https://www.r-pkg.org/badges/version-last-release/httptest)](https://cran.r-project.org/package=httptest)

Testing code and packages that communicate with remote servers can be painful. Dealing with authentication, bootstrapping server state, cleaning up objects that may get created during the test run, network flakiness, and other complications can make testing seem too costly to bother with. But it doesn't need to be that hard. The `httptest` package enables one to test all of the logic on the R sides of the API in your package without requiring access to the remote service. Importantly, `httptest` provides three test **contexts** that mock the network connection in different ways, and it offers additional **expectations** to assert that HTTP requests were--or were not--made. The package also includes a context for recording the responses of real requests and storing them as fixtures that you can later load in a test run. Using these tools, one can test that code is making the intended requests and that it handles the expected responses correctly, all without depending on a connection to a remote API.

This package bridges the gap between two others: (1) [testthat](https://github.com/hadley/testthat), which provides a useful ([and fun](https://github.com/hadley/testthat/blob/master/R/test-that.R#L171)) framework for unit testing in R but doesn't come with tools for testing across web APIs; and (2) [httr](https://github.com/hadley/httr), which [makes working with HTTP in R easy](https://github.com/hadley/httr/blob/master/R/httr.r#L1) but doesn't make it simple to test the code that uses it. `httptest` brings the fun and simplicity together.

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
* **with_mock_API** lets you provide custom fixtures as responses to requests. It maps URLs, including query parameters, to files in your test directory, and it includes the file contents in the mocked "response" object. Request methods that do not have a corresponding fixture file raise errors the same way that `without_internet` does. This context allows you to test more complex R code that makes requests and does something with the response, simulating how the API should respond to specific requests.

### Expectations

* **expect_GET**, **expect_PUT**, **expect_PATCH**, **expect_POST**, and **expect_DELETE** assert that the specified HTTP request is made within one of the test contexts. They catch the error or message raised by the mocked HTTP service and check that the request URL and optional body match the expectation. (Mocked responses in `with_mock_API` just proceed with their response content and don't trigger `expect_GET`, however.)
* **expect_no_request** is the inverse of those: it asserts that no error or message from a mocked HTTP service is raised.
* **expect_header** asserts that an HTTP request, mocked or not, contains a request header.
* **expect_json_equivalent** doesn't directly concern HTTP, but it is useful for working with JSON APIs. It checks that two R objects would generate equivalent JSON, taking into account how JSON objects are unordered whereas R named lists are ordered.

### Recording requests

A fourth context, **capture_requests**, collects the responses from requests you make and stores them as mock files. This enables you to perform a series of requests against a live server once and then build your test suite using those mocks, running your tests in `with_mock_API`.

Mocks stored by `capture_requests` are written out as plain-text files, either with extension `.json` if the request returned JSON content or with extension `.R` otherwise. The `.R` files contain syntax that when executed recreates the `httr` "response" object. By storing fixtures as plain-text files, you can more easily confirm that your mocks look correct, and you can more easily maintain them without having to re-record them. If the API changes subtly, such as when adding an additional attribute to an object, you can just touch up the mocks.

### Other tools

* **skip_if_disconnected** skips following tests if you don't have a working internet connection or can't reach a given URL. This is useful for preventing spurious failures when doing integration tests with a real API.
* **public** is another wrapper around test code that will cause tests to fail if they call functions that aren't "exported" in the package's namespace. Nothing HTTP specific about it, but it's something that I've found useful for preventing accidentally releasing a package without documenting and exporting new functions. While you can use "examples" in the man pages for ensuring that functions you're documenting are exported, code that communicates with remote APIs may not be easily set up to run in a help page example. This context allows you to make those assertions within your test suite.

### FAQ

**Q.** I'm using `capture_requests` but when I try to run tests with those fixtures in `with_mock_API`, the tests are erroring and printing the request URLs. Why aren't the tests finding the mocks?

**A.** First, make sure that your recorded request files are where you think they are and where your tests think they should be. When recording fixtures, keep in mind that the destination path for `capture_requests` is relative to the current working directory of the process. If you're running `capture_requests` within a test suite in an installed package, the working directory may not be the same as your code repository. So either record the requests in an interactive session, or you may have to specify an absolute path if you want to record when running package tests.

If you don't see the captured request files, try specifying `verbose = TRUE` when calling `capture_requests` or `start_capturing`, and it will message the absolute path of the files as it writes them.

Second, once you see where your mock files are, make sure that you've placed the mock directories at the same level of directory nesting as your `test-*.R` files, or if you want them somewhere else, that you've set `.mockPaths` appropriately.

**Q.** I have tests working nicely with `with_mock_API` but `R CMD build` and `R CMD check` warn that my package has "non-portable file paths". How do I make legal file paths that my code and tests will recognize?

**A.** Generally, this error means that there are file paths are longer than 100 characters. Depending on how long your URLs are, there are a few ways to save on characters without compromising readability of your code and tests. First, if you have your tests inside a `tests/testthat/` directory, and your fixture files inside that, you can save 9 characters by moving the fixtures up to `tests/` and setting `.mockPaths("../")`.

If you need to save more, look for places where your URLs contain segments that perhaps could be (or already are) configurable settings. For example, if all of your API endpoints sit beneath `https://language.googleapis.com/v1/`, you could define that in your package as `options(mypackage.api="https://language.googleapis.com/v1/")`, construct your URLs relative to that in the code, and then in your tests, set something different, such as `options(mypackage.api="api/")`. That way, all mocked requests would have a path starting with "api/" rather than "language.googleapis.com/v1/", saving you (in this case) another 23 characters.

You may also be able to economize on other parts of the file paths. If you've recorded requests and your file paths contain long entity ids like "1495480537a3c1bf58486b7e544ce83d", depending on how you access the API in your code, you may be able to simply replace that id with something shorter, like "1". The mocks are just files, disconnected from a real server and API, so you can rename them and munge them as needed.

## Contributing

Suggestions and pull requests are more than welcome. This package was initially pulled together from test setup code I'd written and copied around among three different packages. While the code here has been well used and hashed out over a couple of years of working with them, I have naturally focused on features that have been helpful for working with specific APIs. The concepts provided here are generally useful, but some details or conveniences for working with other APIs may be missing. In particular, the package privileges "Content-Type: application/json" in several places.

## For developers

The repository includes a Makefile to facilitate some common tasks.

### Running tests

`$ make test`. You can also specify a specific test file or files to run by adding a "file=" argument, like `$ make test file=offline`. `test_package` will do a regular-expression pattern match within the file names. See its documentation in the `testthat` package.

### Updating documentation

`$ make doc`. Requires the [roxygen2](https://github.com/klutometis/roxygen) package.
