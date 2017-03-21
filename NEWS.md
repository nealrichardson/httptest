### httptest 1.2.0
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
