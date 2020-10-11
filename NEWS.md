# httptest 3.3.0.9000 (under development)
* Mocking PUT and POST with a body consisting of only `httr::upload_file` no longer leaves a file connection open.
* Mock files with special characters in the filename are now correctly found (#33, @natbprice)
* Switch continuous integration to use GitHub Actions (#36, @jonkeane)

# httptest 3.3.0

* (Re)load package redactors when loading a package interactively with `pkgload::load_all()`, formerly of `devtools` (#15)
* `expect_header()` now defaults to `ignore.case=TRUE` because HTTP header names are case insensitive.
* Support mocking of file uploads via `httr::upload_file` on all platforms (#25)
* Remove deprecated `redact` and `verbose` arguments to `capture_requests`

# httptest 3.2.2

* Patch for compatibility with the upcoming 1.4.0 release of `httr`.

# httptest 3.2.0

* `use_httptest()` for convenience when setting up a new package
* Warn when capturing requests if the `httr` request function errors and no response file is written (#16)
* Support recording with `capture_requests()` when directly calling `GET` et al. interactively with the `httr` package attached (#17)
* Support regular expression matching of URLs and request bodies in `expect_GET()` et al. (#19)

# httptest 3.1.0

## Better, more efficient response recording

* `capture_requests()` no longer includes the "request" object inside the recorded response when writing `.R` verbose responses. As of 3.0.0, `with_mock_api()` inserts the current request when loading mock files, so it was being overwritten anyway. This eliminates some (though not all) of the need for redacting responses. As a result, the redacting functions `redact_oauth()` and `redact_http_auth()` have been removed because they only acted on the `response$request`, which is now dropped entirely.
* `capture_requests()` will record simplified response bodies for a range of Content-Types when `simplify=TRUE` (the default). Previously, only `.json` (`Content-Type: application/json`) was recorded as a simple text files; now, `.html`, `.xml`, `.txt`, `.csv`, and `.tsv` are supported.
* When recording with `simplify=TRUE`, HTTP responses with `204 No Content` status are now written as empty files with `.204` extension. This saves around 2K of disk space per file.
* `with_mock_api()` now can also load these newly supported file types.
* Bare JSON files written by `capture_requests()` are now "prettified" (i.e. multiline, nice indentation).
* `capture_requests()` now records responses from `httr::RETRY()` (#13)

## Vignette setup and teardown

* Store package-level vignette setup and teardown code, called inside `start_vignette()` and `end_vignette()`, in `inst/httptest/start-vignette.R` and `inst/httptest/end-vignette.R`, respectively. Like with the package redactors and request preprocessors, these are automatically executed whenever your package is loaded and `start/end_vignette` is called. This makes it easy to write multiple vignettes without having to copy and paste as much setup code. See `vignette("vignettes")` for details.

## Other enhancements and options

* `gsub_response()` now applies over the URL in a `Location` header, if found.
* Add `options(httptest.max.print)` to allow you the ability to specify a length to which to truncate the request body printed in the error message for requests in `with_mock_api()`. Useful for debugging mock files not found when there are large request bodies.
* Add `options(httptest.debug)`, which if `TRUE` prints more details about which functions are being traced (by `base::trace()`) and when they're called.
* Deprecate the "verbose" argument to `capture_requests()`: use `options(httptest.verbose)` instead.

# httptest 3.0.0

## Major features
* Write vignettes and other R Markdown documents that communicate with a remote API using `httptest`. Add a code chunk at the beginning of the document including `start_vignette()`. The first time you run the document, the real API responses are recorded to a subfolder in your `vignettes` directory. Subsequent vignette builds use these recorded responses, allowing the document to regenerate without a network connection or API credentials. If your document needs to handle changes of server state, as when you make an API request that creates a record on the server, add a call to `change_state()`. See `vignette("vignettes")` for more discussion and links to examples.
* Packages can now have a default redacting function, such that whenever the package is loaded, `capture_requests()` will apply that function to any responses it records. This ensures that you never forget to sanitize your API responses if you need to use a custom function. To take advantage of this feature, put a `function (response) {...}` in a file at `inst/httptest/redact.R` in your package. See the updated `vignette("redacting", package="httptest")` for more.
* You can also now provide a function to preprocess mock requests. This can be particularly for shortening URLs---and thus the mock file paths---because of CRAN-mandated constraints on file path lengths ("non-portable file paths"). This machinery works very similar to redacting responses when recording them, except it operates on `request` objects inside of `with_mock_api()`. To use it, either pass a `function (request) {...}` to `set_requester()` in your R session, or to define one for the package, put a `function (request) {...}` in a file at `inst/httptest/request.R`. `gsub_request()` is particularly useful here. `vignette("redacting", package="httptest")` has further details.

## Other big changes and enhancements
* Standardize exported functions on `snake_case` rather than `camelCase` to better align with `httr` and `testthat` (except for `.mockPaths()`, which follows `base::.libPaths()`). Exported functions that have been renamed have retained their old aliases in this release, but they are to be deprecated.
* `use_mock_api()` and `block_requests()` enable the request altering behavior of `with_mock_api()` and `without_internet()`, respectively, without the enclosing context. (`use_mock_api` is called inside `start_vignette()`.) To turn off mocking, call `stop_mocking()`.
* Internal change: mocking contexts no longer use `testthat::with_mock()` and instead use `trace()`.
* `capture_requests()`/`start_capturing()` now allow you to call `.mockPaths()` while actively recording so that you can record server state changes to a different mock "layer". Previously, the recording path was fixed when the context was initialized.
* The `redact` argument to `capture_requests()`/`start_capturing()` is deprecated in favor of `set_redactor()`. This function can take a `function (response) {...}`; a formula as shorthand for an anonymous function with `.` as the "response" argument, as in the [`purrr`](https://purrr.tidyverse.org) package; a list of functions that will be chained together; or `NULL` to disable the default `redact_auth()`.
* `redact_headers()` and `within_body_text()` no longer return redacting functions. Instead, they take `response` as their first argument. This makes them more natural to use and chain together in custom redacting functions. To instead return a function as before, see `as.redactor()`.
* `gsub_response()` is a new redactor that does regular-expression replacement (via `base::gsub()`) within a response's body text and URL.
* `.mockPaths()` only keeps unique path values, consistent with `base::.libPaths()`.
* Option `"httptest.verbose"` to govern some extra debug messaging (automatically turned off by `start_vignette()`)
* Fix a bug where `write_disk` responses that were recorded in one location and moved to another directory could not be loaded

# httptest 2.3.4
* Ensure forward compatibility with a [change](https://github.com/wch/r-source/commit/62fced00949b9a261034d24789175b205f7fa866) in `deparse()` in the development version of R (r73699).

# httptest 2.3.2
* Add `redact_oauth()` to purge `httr::Token()` objects from requests ([#9](https://github.com/nealrichardson/httptest/issues/9)). `redact_oauth()` is built in to `redact_auth()`, the default redactor, so no action is required to start using it.

# httptest 2.3.0
* Remove support for mocking `utils::download.file()`, as `testthat` no longer permits it. Use `httr::GET(url, config=write_disk(filename))` instead, which `httptest` now more robustly supports in `capture_requests()`.

# httptest 2.2.0
* Add redacting functions (`redact_auth()`, `redact_cookies()`, `redact_http_auth()`, `redact_headers()`, `within_body_text()`) that can be specified in `capture_requests()` so that sensitive information like tokens and ids can be purged from recorded response files. The default redacting function is `redact_auth()`, which wraps several of them. See `vignette("redacting", package="httptest")` for more.
* When loading a JSON mock response, the current "request" object is now included in the response returned, as is the case with real responses.
* Remove the file size limitation for mock files loaded in `with_mock_api()`
* `skip_if_disconnected()` now also wraps `testthat::skip_on_cran()` so that tests that require a real network connection don't cause a flaky test failure on CRAN

# httptest 2.1.2
* Fix for compatibility with upcoming release of [httr](http://httr.r-lib.org/) that affected non-GET requests that did not contain any request body.

# httptest 2.1.0
* `with_mock_api()` and `without_internet()` handle multipart and urlencoded form data in mocked HTTP requests.
* `buildMockURL()` escapes URL characters that are not valid in file names on all R platforms (which `R CMD check` would warn about).
* `capture_requests()` now has a `verbose` argument, which, if `TRUE`, prints a message with the file path where each captured request is written.
* `capture_requests()` takes the first element in `.mockPaths()` as its default "path" argument. The default is unchanged since `.mockPaths()` by default returns the current working directory, just as the "path" default was, but if you set a different mock path for reading mocks, `capture_requests()` will write there as well.

# httptest 2.0.0
* `capture_requests()` now writes non-JSON-content-type and non-200-status responses as full "response" objects in .R files. `with_mock_api()` now looks for .R mocks if a .json mock isn't found. This allows all requests and all responses, not just JSON content, to be mocked.
* New `.mockPaths()` function, in the model of `.libPaths()`, which allows you to specify alternate directories in which to search for mock API responses.
* Documentation enriched and `vignette("httptest")` added.

# httptest 1.3.0
* New context `capture_requests()` to collect the responses from real requests and store them as mock files
* `with_trace()` convenience wrapper around `trace`/`untrace`
* `mockDownload()` now processes request URLs as `mock_request()` does

# httptest 1.2.0
* Add support in `with_mock_api()` for loading request fixtures for all HTTP verbs, not only GET ([#4](https://github.com/nealrichardson/httptest/pull/4)). Include request body in the mock file path hashing.
* `buildMockURL()` can accept either a 'request' object or a character URL
* Bump mock payload max size up to 128K

# httptest 1.1.2
* Support full URLs, not just file paths, in `with_mock_api()` ([#1](https://github.com/nealrichardson/httptest/issues/1))

# httptest 1.1.0

* `expect_header()` to assert that a HTTP request has a header
* Always prune the leading ":///" that appears in `with_mock_api()` if the URL has a querystring

# httptest 1.0.0

* Initial addition of functions and tests, largely pulled from [httpcache](https://enpiar.com/r/httpcache) and [crunch](https://crunch.io/r/crunch).
