## httptest 2.1.0
* `with_mock_API` and `without_internet` handle multipart and urlencoded form data in mocked HTTP requests.
* `buildMockURL` escapes URL characters that are not valid in file names on all R platforms (which `R CMD check` would warn about).
* `capture_requests` now has a `verbose` argument, which, if `TRUE`, prints a message with the file path where each captured request is written.
* `capture_requests` takes the first element in `.mockPaths` as its default "path" argument. The default is unchanged since `.mockPaths` by default returns the current working directory, just as the "path" default was, but if you set a different mock path for reading mocks, `capture_requests` will write there as well.

# httptest 2.0.0
* `capture_requests` now writes non-JSON-content-type and non-200-status responses as full "response" objects in .R files. `with_mock_API` now looks for .R mocks if a .json mock isn't found. This allows all requests and all responses, not just JSON content, to be mocked.
* New `.mockPaths` function, in the model of `.libPaths`, which allows you to specify alternate directories in which to search for mock API responses.
* Documentation enriched and a [vignette](https://github.com/nealrichardson/httptest/blob/master/inst/doc/httptest.md) added.

## httptest 1.3.0
* New context `capture_requests` to collect the responses from real requests and store them as mock files
* `with_trace` convenience wrapper around `trace`/`untrace`
* `mockDownload` now processes request URLs as `mockRequest` does

## httptest 1.2.0
* Add support in `with_mock_API` for loading request fixtures for all HTTP verbs, not only GET ([#4](https://github.com/nealrichardson/httptest/pull/4)). Include request body in the mock file path hashing.
* `buildMockURL` can accept either a 'request' object or a character URL
* Bump mock payload max size up to 128K

### httptest 1.1.2
* Support full URLs, not just file paths, in `with_mock_API` ([#1](https://github.com/nealrichardson/httptest/issues/1))

## httptest 1.1.0

* `expect_header` to assert that a HTTP request has a header
* Always prune the leading ":///" that appears in `with_mock_API` if the URL has a querystring

# httptest 1.0.0

* Initial addition of functions and tests, largely pulled from [httpcache](https://github.com/nealrichardson/httpcache) and [crunch](https://github.com/Crunch-io/rcrunch).
