# httptest: A Test Environment for HTTP Requests in R

[![Build Status](https://github.com/nealrichardson/httptest/workflows/R-CMD-check/badge.svg)](https://github.com/nealrichardson/httptest/actions) [![codecov](https://codecov.io/gh/nealrichardson/httptest/branch/master/graph/badge.svg)](https://codecov.io/gh/nealrichardson/httptest)
[![cran](https://www.r-pkg.org/badges/version-last-release/httptest)](https://cran.r-project.org/package=httptest) [![CII Best Practices](https://bestpractices.coreinfrastructure.org/projects/2136/badge)](https://bestpractices.coreinfrastructure.org/projects/2136)

`httptest` makes it easy to write tests for code and packages that wrap web APIs.
Testing code that communicates with remote servers can otherwise be painful: things like authentication, server state, and network flakiness can make testing seem too costly to bother with. The `httptest` package enables you to test all of the logic on the R sides of the API in your package without requiring access to the remote service.

Importantly, it provides multiple **contexts** that mock the network connection and tools for **recording** real requests for future offline use as fixtures, both in tests and in vignettes. The package also includes additional **expectations** to assert that HTTP requests were---or were not---made.

Using these tools, you can test that code is making the intended requests and that it handles the expected responses correctly, all without depending on a connection to a remote API. The ability to save responses and load them offline also enables you to write package vignettes and other dynamic documents that can be distributed without access to a live server.

This package bridges the gap between two others: (1) [testthat](http://testthat.r-lib.org/), which provides a useful ([and fun](https://github.com/r-lib/testthat/blob/master/R/test-that.R#L171)) framework for unit testing in R but doesn't come with tools for testing across web APIs; and (2) [httr](http://httr.r-lib.org/), which [makes working with HTTP in R easy](https://github.com/r-lib/httr/blob/master/R/httr.r#L1) but doesn't make it simple to test the code that uses it. `httptest` brings the fun and simplicity together.

## Installing

`httptest` can be installed from CRAN with

```r
install.packages("httptest")
```

The pre-release version of the package can be pulled from GitHub using the [remotes](https://github.com/r-lib/remotes) package (formerly part of and now a dependency of `devtools`):

```r
# install.packages("remotes")
remotes::install_github("nealrichardson/httptest")
```

## Using

To start using `httptest` with your package, run `use_httptest()` in the root of your package directory. This will

* add `httptest` to "Suggests" in the DESCRIPTION file
* add `library(httptest)` to `tests/testthat/helper.R`, which `testthat` loads before running tests

Then, you're ready to start using the tools that `httptest` provides. Here's an overview of how to get started. For a longer discussion and examples, see `vignette("httptest")`, and see also the [package reference](https://enpiar.com/r/httptest/reference/) for a list of all of the test contexts and expectations provided in the package.

### In your test suite

The package includes several contexts, which you wrap around test code that would otherwise make network requests through `httr`. They intercept the requests and prevent actual network traffic from occurring.  

**`with_mock_api()`** maps requests---URLs along with request bodies and query parameters---to file paths. If the file exists, its contents are returned as the response object, as if the API server had returned it. This allows you to test complex R code that makes requests and does something with the response, simulating how the API should respond to specific requests.

Requests that do not have a corresponding fixture file raise errors that print the request method, URL, and body payload, if provided. **`expect_GET()`**, **`expect_POST()`**, and the rest of the HTTP-request-method expectations look for those errors and check that the requests match the expectations. These are useful for asserting that a function call would make a correctly-formed HTTP request without the need to generate a mock, as well as for asserting that a function does not make a request (because if it did, it would raise an error in this context).

Adding `with_mock_api()` to your tests is straightforward. Given a very basic test that makes network requests:

```r
test_that("Requests happen", {
    expect_is(GET("http://httpbin.org/get"), "response")
    expect_is(
        GET("http://httpbin.org/response-headers",
            query=list(`Content-Type`="application/json")),
        "response"
    )
})
```

if we wrap the code in `with_mock_api()`, actual requests won't happen.

```r
with_mock_api({
    test_that("Requests happen", {
        expect_is(GET("http://httpbin.org/get"), "response")
        expect_is(
            GET("http://httpbin.org/response-headers",
                query=list(`Content-Type`="application/json")),
            "response"
        )
    })
})
```

Those requests will now raise errors unless we either (1) wrap them in `expect_GET()` and assert that we expect those requests to happen, or (2) supply mocks in the file paths that match those requests. We might get those mocks from the documentation for the API we're using, or we could record them ourselves---and `httptest` provides tools for recording.

Another context, **`capture_requests()`**, collects the responses from requests you make and stores them as mock files. This enables you to perform a series of requests against a live server once and then build your test suite using those mocks, running your tests in `with_mock_api`.

In our example, running this once:

```r
capture_requests({
    GET("http://httpbin.org/get")
    GET("http://httpbin.org/response-headers",
        query=list(`Content-Type`="application/json"))
})
```

would make the actual requests over the network and store the responses where `with_mock_api()` will find them.  

For convenience, you may find it easier in an interactive session to call `start_capturing()`, make requests, and then `stop_capturing()` when you're done, as in:

```r
start_capturing()
GET("http://httpbin.org/get")
GET("http://httpbin.org/response-headers",
    query=list(`Content-Type`="application/json"))
stop_capturing()
```

Mocks stored by `capture_requests` are written out as plain-text files. By storing fixtures as human-readable files, you can more easily confirm that your mocks look correct, and you can more easily maintain them if the API changes subtly without having to re-record them (though it is easy enough to delete and recapture). Text files also play well with version control systems, such as git.

When recording requests, `httptest` redacts the standard ways that auth credentials are passed, so you won't accidentally publish your personal tokens. The redacting behavior is fully customizable: you can programmatically sanitize or alter other parts of the request and response. See `vignette("redacting")` for details.

### In your vignettes

Package vignettes are a valuable way to show how to use your code, but when communicating with a remote API, it has been difficult to write useful vignettes. With `httptest`, however, by adding as little as one line of code to your vignette, you can safely record API responses from a live session, using your secret credentials. These API responses are scrubbed of sensitive personal information and stored in a subfolder in your `vignettes` directory. Subsequent vignette builds, including on continuous-integration services, CRAN, and your package users' computers, use these recorded responses, allowing the document to regenerate without a network connection or API credentials. To record fresh API responses, delete the subfolder of cached responses and re-run.

To use `httptest` in your vignettes, add a code chunk with `start_vignette()` at the beginning, and for many use cases, that's the only thing you need. If you need to handle changes of server state, as when you make an API request that creates a record on the server, add a call to `change_state()`. See `vignette("vignettes")` for more discussion and links to examples.

### FAQ

#### Where are my mocks recorded?

By default, the destination path for `capture_requests()` is relative to the current working directory of the process. This matches the behavior of `with_mock_api()`, which looks for files relative to its directory, which typically is `tests/testthat/`.

If you're running `capture_requests` within a test suite in an installed package, or if you're running interactively from a different directory, the working directory may not be the same as your code repository. If you aren't sure where the files are going, set `options(httptest.verbose=TRUE)`, and it will message the absolute path of the files as it writes them.

To change where files are being written or read from, use `.mockPaths()` (like `base::.libPaths()`) to specify a different directory.

#### How do I fix "non-portable file paths"?

If you see this error in `R CMD build` or `R CMD check`, it means that there are file paths are longer than 100 characters, which can sometimes happen when you record requests. `httptest` preserves the URL structure of mocks in file paths to improve the readability and maintainability of your tests, as well as to make visible the properties of your API.
Indeed, the file-system tree view of the mock files gives a visual representation of your API. This value comes with a tradeoff: sometimes URLs can be long, and R doesn't like that.

Depending on how long your URLs are, there are a few ways to save on characters without compromising readability of your code and tests.

A big way to cut long file paths is by using a request preprocessor: a function that alters the content of your 'httr' `request` before mapping it to a mock file. For example, if all of your API endpoints sit beneath `https://language.googleapis.com/v1/`, you could set a request preprocessor like:

```r
set_requester(function (request) {
    gsub_request(request, "https\\://language.googleapis.com/v1/", "api/")
})
```

and then all mocked requests would look for a path starting with "api/" rather than "language.googleapis.com/v1/", saving you (in this case) 23 characters.

You can also provide this function in `inst/httptest/request.R`, and any time your package is loaded (as when you run tests or build vignettes), this function will be called automatically. See `vignette("redacting")` for more.

You may also be able to economize on other parts of the file paths. If you've recorded requests and your file paths contain long ids like "1495480537a3c1bf58486b7e544ce83d", depending on how you access the API in your code, you may be able to simply replace that id with something shorter, like "1". The mocks are just files, disconnected from a real server and API, so you can rename them and munge them as needed.

Finally, if you have your tests inside a `tests/testthat/` directory, and your fixture files inside that, you can save 9 characters by moving the fixtures up to `tests/` and setting `.mockPaths("../")`.

#### How do I switch between mocking and real requests?

**Q.** I'd like to run my mocked tests sometimes against the real API, perhaps to turn them into integration tests, or perhaps to use the same test code to record the mocks that I'll later use. How can I do this without copying the contents of the tests inside the `with_mock_api()` blocks?

**A.** One way to do this is to set `with_mock_api()` to another function in your test file (or in `helper.R` if you want it to run for all test files). So

```r
with_mock_api({
    a <- GET("https://httpbin.org/get")
    print(a)
})
```

looks for the mock file, but

```r
with_mock_api <- force
with_mock_api({
    a <- GET("https://httpbin.org/get")
    print(a)
})
```

just evaluates the code with no mocking and makes the request, and

```r
with_mock_api <- capture_requests
with_mock_api({
    a <- GET("https://httpbin.org/get")
    print(a)
})
```

would make the request and record the response as a mock file. You could control this behavior with environment variables by adding something like

```r
if (Sys.getenv("MOCK_BYPASS") == "true") {
    with_mock_api <- force
} else if (Sys.getenv("MOCK_BYPASS") == "capture") {
    with_mock_api <- capture_requests
}
```

to your `helper.R` or `setup.R`.

You could also experiment with using `start_vignette()`, which switches behavior based on the existence of the specified mock directory.

## Contributing

Suggestions and pull requests are more than welcome!

## For developers

The repository includes a Makefile to facilitate some common tasks from the command line, if you're into that sort of thing.

### Running tests

`$ make test`. You can also specify a specific test file or files to run by adding a "file=" argument, like `$ make test file=offline`. `test_package` will do a regular-expression pattern match within the file names. See its documentation in the `testthat` package.

### Updating documentation

`$ make doc`. Requires the [roxygen2](https://github.com/klutometis/roxygen) package.
