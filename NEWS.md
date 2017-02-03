## httptest 1.1.0

* `expect_header` to assert that a HTTP request has a header
* Always prune the leading ":///" that appears in `with_mock_API` if the URL has a querystring

# httptest 1.0.0

* Initial addition of functions and tests, largely pulled from [httpcache](https://github.com/nealrichardson/httpcache) and [crunch](https://github.com/Crunch-io/rcrunch).
