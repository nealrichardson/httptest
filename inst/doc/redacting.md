<!--
%\VignetteEngine{knitr::knitr}
%\VignetteIndexEntry{Redacting Sensitive Information from Recorded Requests}
%\VignetteEncoding{UTF-8}
-->

# Redacting Sensitive Information from Recorded Requests

`httptest` makes it easy for you to write tests that don't require a network connection. With `capture_requests()`, you can record responses from real requests so that you can use them later in tests. A further benefit of testing with mocks is that you don't have to deal with authentication and authorization on the server in your tests---you don't need to supply real login credentials for your test suite to run. You can have full test coverage of your code, both on public continuous-integration services like Travis-CI and when you submit packages to CRAN, all without having to publish secret tokens or passwords.

It is important to ensure that the mocks you include in your test suite do not inadvertently reveal private information as well. For many requests and responses, the default behavior of `capture_requests` is to write out only the response body, which makes for clean, easy-to-read test fixtures. For other responses, however---those returning non-JSON content or an error status---it writes a `.R` file containing a `httr` "response" object. This response contains all of the headers and cookies that the server returns, and it also has a copy of your "request" object, with the headers, tokens, and other configuration you sent to the server. If not addressed, this would mean that you might be exposing your personal credentials publicly.

Starting in version 2.2.0, `httptest` provides a framework for sanitizing the responses that `capture_requests` records. By default, it redacts the standard ways that auth credentials are passed in requests: cookies, authorization headers, and basic HTTP auth. The framework is extensible and allows you to specify custom redaction policies that match how your API accepts and returns sensitive information. Common redacting functions are configurable and natural to adapt to your needs, while the workflow also supports custom redacting functions that can alter the recorded requests however you want, including altering the response content and URL.

## Default: redact standard auth methods

By default, the `capture_requests` context evaluates the `redact_auth()` function on a response object before writing it to disk. `redact_auth` wraps a few smaller redacting functions that (1) sanitize any cookies in the request and response; (2) redact common headers including "Authorization", if present; and (3) if using basic HTTP authentication with username and password, removes those credentials.

What does "redacting" entail? We aren't the CIA working with classified reports, taking a heavy black marker over certain details. In our case, redacting means replacing the sensitive content with the string "REDACTED". Your recorded responses will be as "real" as possible: if, for example, you have an "Authorization" header in your request, the header will remain in your test fixture, but real token value will be replaced with "REDACTED". And only the recorded responses will be affected---the actual response you're capturing in your active R session is not modified, only the mock that is written out.

To illustrate, if you make a request that includes a cookie, that cookie will also be included in the `response` object that is returned.

```r
capture_requests(simplify=FALSE, {
    real_resp <- GET("http://httpbin.org/cookies", set_cookies(token="12345"))
})
real_resp$request$options$cookie

## [1] "token=12345"
```

But when we load that recorded response in tests later, the cookie won't appear because it was redacted:

```r
with_mock_API({
    alt_resp <- GET("http://httpbin.org/cookies", set_cookies(token="12345"))
})
alt_resp$request$options$cookie

## [1] "REDACTED"
```

(Side note: the example uses the `simplify=FALSE` option to `capture_requests` for illustration purposes. With the default `simplify=TRUE`, only the response body would be written to a mock file because this particular GET request returns JSON content. Thus, there would be no cookie present anyway. `simplify=FALSE` forces `capture_requests` to write the verbose .R response object file for every request, not just those that don't return JSON content.)

## Handling other auth methods

Some APIs use other methods for passing credentials. For example, the [API for Pivotal Tracker](https://www.pivotaltracker.com/help/api), the agile project management tool, uses a "X-TrackerToken" request header for passing an API token. Our standard redactor doesn't know about this header, so by default, this token would be written in our recorded responses.

So, in the [pivotaltrackR](https://github.com/nealrichardson/pivotaltrackR) package, which wraps this API, if we want to record mocks to use in tests with this API, we need to tell `capture_requests` to scrub its special header. To do this, we'll set `redact=redact_headers("X-TrackerToken")` in the capture call.

To illustrate, here's a recording of a GET on the `stories/` endpoint. We can see that the real token is included in the "X-TrackerToken" header in the real request:

```r
library(httptest)
library(pivotaltrackR)
options(pivotal.project="my-project-name", pivotal.token="8fe3452ac4e3")

capture_requests(redact=redact_headers("X-TrackerToken"), simplify=FALSE, {
    active_stories <- getStories(state="started")
})
active_stories$request$headers

##                                                   Accept
##       "application/json, text/xml, application/xml, */*"
##                                               user-agent
## "libcurl/7.51.0 curl/2.3 httr/1.2.1 pivotaltrackR/0.1.0"
##                                           X-TrackerToken
##                                           "8fe3452ac4e3"
```

Because we set `redact_headers("X-TrackerToken")` as the redactor, it should have been removed from the mock file that was written out. Let's read in that file and inspect it.

```r
mockfile <- "www.pivotaltracker.com/services/v5/projects/my-project-name/stories-c0a029.R"
mock <- source(mockfile)$value
mock$request$headers

##                                                   Accept
##       "application/json, text/xml, application/xml, */*"
##                                               user-agent
## "libcurl/7.51.0 curl/2.3 httr/1.2.1 pivotaltrackR/0.1.0"
##                                           X-TrackerToken
##                                               "REDACTED"
```

The actual token was removed, and in its place is the string "REDACTED". I am now safe to commit this mock file to my repository and publish it without exposing my real credentials.

## Writing custom redacting functions

Sensitive or personal information can also found in other parts of the request and response. Sometimes personal identifiers are built into URLs or response bodies. These may be less sensitive than auth tokens, but you probably want to conceal or anonymize your data that is included in test fixtures.

Redacting functions can help with this personal information as well. You can use redactors on any part of the response object, not just the headers and cookies. A redactor is just a function that takes a response as input and returns a response object, so anything is possible if you write a custom redactor.

Keeping with the `pivotaltrackR` example, note that the Pivotal project id, stored in `options(pivotal.project)` in the R session, appears in the mock file path. It's in the file path because it's in the request URL, and it turns out that many API responses also include it in the response body. We'd rather not have that information leak in our test fixtures, so let's write a function to remove it.

All of the redactors we've seen here functions that take the "response" object as their only argument and return the response object modified in some way. In the previous step, we passed as our redactor `redact_headers("X-TrackerToken")`; this worked because `redact_headers` itself is not a redactor but rather a function that returns a redacting function. When evaluated, `redact_headers("X-TrackerToken")` returns a `function (response) ...` that is called on the response.

We'll start our custom redactor with that header purging, then do some more work, and then return the response:

```r
redact_pivotal <- function (response) {
    response <- redact_headers("X-TrackerToken")(response)
    ...
    return(response)
}
```

What is that "more work" we want to do? Let's say that we want to replace my project id with "123" everywhere it is found, both in the URL and in the response body. Let's start by defining a function that takes a string value and does that replacement, and then we can apply it everywhere. To remove the project id from the response body, we can use the helper `within_body_text`, which takes as its argument a function and returns a redactor (which we then evaluate on "response"). `within_body_text` is helpful because `response` objects have their "content" stored as raw binary vectors, and it handles the `rawToChar`/`charToRaw` wrapping so that you don't have to remember to deal with that.

```r
redact_pivotal <- function (response) {
    redact_pivotal_token <- redact_headers("X-TrackerToken")
    # Function that replaces my project id in a given string
    remove_project <- function (x) gsub(getOption("pivotal.project"), "123", x)
    remove_project_from_body <- within_body_text(remove_project)

    # Remove token from special header
    response <- redact_pivotal_token(response)
    # Remove from URL--note that it appears twice!
    response$url <- remove_project(response$url)
    response$request$url <- remove_project(response$request$url)
    # Now remove from the response body
    response <- remove_project_from_body(response)
    return(response)
}
```

To see this in action, let's record a request:

<!-- show the output -->
```r
start_capturing(redact=redact_pivotal)
s <- getStories(search="mnt")
stop_capturing()
```

Note that the actual project id appears in the data returned from the search.

```r
s[[1]]$project_id
## [1] "my-project-name"
```

However, the project id won't be found in the recorded file. If we load the recorded response in `with_mock_API`, we'll see the value we substituted in:

```r
with_mock_API({
    s <- getStories(search="mnt")
})
s[[1]]$project_id
## [1] "123"
```

Nor will the project id appear in the file path: since the redactor is evaluated before determining the file path to write to, if you alter the response URL, the destination file path will be generated based on the modified URL. In this case, our mock is written to ".../projects/123/stories-fb1776.json", not ".../projects/my-project-name/stories-fb1776.json". This feature can be helpful not only for removing sensitive data from your mock files but also for helping you resolve any "non-portable file paths" errors that `R CMD check` throws. File paths in packages are required to be under 100 characters long in order to maintain compatibility with old file systems. When dealing with APIs that have long URLs, you may run into this limit. But in this example, by replacing "my-project-name" with "123", we cut 12 characters from the mock file paths, which will help with this check requirement.

Finally, an observation about how to incorporate custom redactors into your testing workflow. One way to build it in is to define the redactor in your `tests/testthat/helper.R` file, and then override `capture_requests` with a version that uses your redactor, like this:

```r
capture_requests <- function (...) {
    httptest::capture_requests(redact=redact_pivotal, ...)
}
```

So whenever you record requests from within your test setup, the redaction is automatically applied.
