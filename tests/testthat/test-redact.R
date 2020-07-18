context("Redaction")

d <- tempfile()

with_mock_api({
    # Auth headers aren't recorded
    capture_while_mocking(simplify=FALSE, path=d, {
        a <- GET("api/", add_headers(`Authorization`="Bearer token"))
    })
    test_that("The response has the real request header", {
        expect_equal(a$request$headers[["Authorization"]], "Bearer token")
    })
    test_that("But the mock file does not", {
        expect_false(any(grepl("Bearer token", readLines(file.path(d, "api.R")))))
    })
    test_that("And the redacted .R mock can be loaded", {
        with_mock_path(d, {
            b <- GET("api/", add_headers(`Authorization`="Bearer token"))
        })
        expect_equal(content(b), content(a))
    })

    # Request cookies aren't recorded
    capture_while_mocking(simplify=FALSE, path=d, {
        cooks <- GET("http://httpbin.org/cookies", set_cookies(token="12345"))
    })
    test_that("redact_cookies: the response has the cookie set in the request", {
        expect_identical(cooks$request$options$cookie, "token=12345")
    })
    test_that("redact_cookies removes cookies from request in the mock file", {
        cooksfile <- readLines(file.path(d, "httpbin.org", "cookies.R"))
        expect_false(any(grepl("token=12345", cooksfile)))
    })
    test_that("And the redacted .R mock can be loaded", {
        with_mock_path(d, {
            cooksb <- GET("http://httpbin.org/cookies", set_cookies(token="12345"))
        })
        expect_equal(content(cooksb), content(cooks))
    })

    # redact_cookies from response
    capture_while_mocking(simplify=FALSE, path=d, {
        c2 <- GET("http://httpbin.org/cookies/set", query=list(token=12345))
    })
    test_that("redact_cookies: the response has the set-cookie in the response", {
        # Note the "all_headers": the request did a 302 redirect
        expect_identical(c2$all_headers[[1]]$headers[["set-cookie"]],
            "token=12345; Path=/")
        expect_identical(c2$cookies$value, "12345")

    })
    test_that("redact_cookies removes set-cookies from response in the mock file", {
        # Note that "token=12345" appears in the request URL because of how
        # httpbin works. But normally your cookie wouldn't be in the URL.
        # Of course, if you wanted to sanitize URLs too, you could write your
        # own custom redacting function.
        expect_false(any(grepl('"token=12345',
            readLines(file.path(d, "httpbin.org", "cookies", "set-5b2631.R")))))
        expect_length(grep("REDACTED",
            readLines(file.path(d, "httpbin.org", "cookies", "set-5b2631.R"))),
            2)
    })
    test_that("And when loading that .R mock, the redacted value doesn't appear", {
        with_mock_path(d, {
            c2b <- GET("http://httpbin.org/cookies/set", query=list(token=12345))
        })
        expect_identical(c2b$all_headers[[1]]$headers[["set-cookie"]],
            "REDACTED")
        expect_identical(c2b$cookies$value, "REDACTED")
    })

    # another redact_cookies with POST example.com/login
    capture_while_mocking(simplify=FALSE, path=d, {
        login <- POST("http://example.com/login",
            body=list(username="password"), encode="json")
    })
    test_that("redact_cookies: the response has the set-cookie in the response", {
        # Note the "all_headers": the request did a 302 redirect
        expect_true(grepl("token=12345",
            login$all_headers[[1]]$headers[["set-cookie"]]))
        expect_true(grepl("token=12345",
            login$headers[["set-cookie"]]))
        expect_identical(login$cookies$value, "12345")
    })
    test_that("redact_cookies removes set-cookies from response in the mock file", {
        # Unlike other example, token=12345 isn't in the URL
        expect_false(any(grepl("12345",
            readLines(file.path(d, "example.com", "login-712027-POST.R")))))
        expect_length(grep("REDACTED",
            readLines(file.path(d, "example.com", "login-712027-POST.R"))),
            3)
    })
    test_that("And when loading that .R mock, the redacted value doesn't appear", {
        with_mock_path(d, {
            loginb <- POST("http://example.com/login",
                body=list(username="password"), encode="json")
        })
        expect_identical(loginb$all_headers[[1]]$headers[["set-cookie"]],
            "REDACTED")
        expect_identical(loginb$headers[["set-cookie"]], "REDACTED")
        expect_identical(loginb$cookies$value, "REDACTED")
    })

    # HTTP auth credentials aren't recorded
    capture_while_mocking(simplify=FALSE, path=d, {
        pwauth <- GET("http://httpbin.org/basic-auth/user/passwd",
            authenticate("user", "passwd"))
    })
    test_that("redact_http_auth: the request has the user:pw set", {
        expect_identical(pwauth$request$options$userpwd, "user:passwd")
    })
    test_that("redact_http_auth removes user:pw from request in the mock file", {
        expect_false(any(grepl("user:passwd",
            readLines(file.path(d, "httpbin.org", "basic-auth", "user", "passwd.R")))))
    })
    test_that("And the redacted .R mock can be loaded", {
        with_mock_path(d, {
            pwauthb <- GET("http://httpbin.org/basic-auth/user/passwd",
                authenticate("user", "passwd"))
        })
        expect_equal(content(pwauthb), content(pwauth))
    })

    # OAuth credentials aren't recorded
    # Example token copied from a test in httr
    token <- Token2.0$new(
        app = oauth_app("x", "y", "z"),
        endpoint = oauth_endpoints("google"),
        credentials = list(access_token = "ofNoArms")
    )
    token$params$as_header <- TRUE
    capture_while_mocking(simplify=FALSE, path=d, {
        oauth <- GET("api/object1/", config(token = token))
    })
    test_that("The response has the 'auth_token' object'", {
        expect_is(oauth$request$auth_token, "Token2.0")
    })

    test_that("But the mock doesn't have the auth_token", {
        oauthfile <- readLines(file.path(d, "api", "object1.R"))
        expect_false(any(grepl("auth_token", oauthfile)))
    })
    test_that("And the .R mock can be loaded", {
        with_mock_path(d, {
            oauthb <- GET("api/object1/", config(token = token))
        })
        expect_equal(content(oauthb), content(oauth))
    })

    # Custom redacting function
    my_redactor <- function (response) {
        # Proof that you can alter other parts of the response/mock
        response$url <- response$request$url <- "http://example.com/fakeurl"
        # Proof that you can alter the response body
        cleaner <- function (x) gsub("loaded", "changed", x)
        response <- within_body_text(response, cleaner)
        return(response)
    }
    with_redactor(my_redactor,
        capture_while_mocking(simplify=FALSE, path=d, {
            r <- GET("http://example.com/get")
        })
    )
    test_that("The real request is not affected by the redactor", {
        expect_identical(r$url, "http://example.com/get")
        expect_identical(content(r), list(loaded=TRUE))
    })
    test_that("But the mock file gets written to the modified path with altered content", {
        options(httptest.mock.paths=d)  ## Do this way to make sure "." isn't in
                                        ## the search path. We're checking that
                                        ## the original request doesn't have a
                                        ## mock, but of course we made it from
                                        ## a mock in the working directory
        on.exit(options(httptest.mock.paths=NULL))
        expect_GET(GET("http://example.com/get"),
            "http://example.com/get")
        expect_error(alt <- GET("http://example.com/fakeurl"), NA)
        expect_identical(content(alt), list(changed=TRUE))
    })

    a <- GET("api/", add_headers(`Authorization`="Bearer token"))
    test_that("gsub_response", {
        asub <- gsub_response(a, "api", "OTHER")
        expect_identical(asub$url, "OTHER/")
        expect_identical(content(asub), list(value="OTHER/object1/"))
    })
    test_that("as.redactor", {
        a2 <- prepare_redactor(~ gsub_response(., "api", "OTHER"))(a)
        expect_identical(content(a2), list(value="OTHER/object1/"))
    })

    loc <- GET("http://httpbin.org/response-headers",
        query=list(Location="http://httpbin.org/status/201"))
    loc_sub <- gsub_response(loc, "http://httpbin.org/status/201",
        "http://httpbin.org/status/404")
    test_that("gsub_response touches Location header", {
        expect_identical(loc_sub$headers$location,
            "http://httpbin.org/status/404")
        expect_identical(loc_sub$all_headers[[1]]$headers$location,
            "http://httpbin.org/status/404")
        expect_identical(content(loc_sub)$Location,
            "http://httpbin.org/status/404")
    })
    test_that("gsub_response handles URL encoding", {
        skip("TODO: handle URL escaping")
        expect_identical(loc_sub$url,
            "http://httpbin.org/response-headers?Location=http%3A%2F%2Fhttpbin.org%2Fstatus%2F404")
    })
})


with_fake_http({
    expect_PUT(
        p <- PUT("http://httpbin.org/put",
            body = list(x = "A string", string = "Something else")
        )
    )
    req <- p$request
    ## TODO: more gsub_request tests
    test_that("gsub_request on non-JSON post fields", {
        expect_identical(gsub_request(req, "string", "SECRET")$fields,
            list(x = "A SECRET", SECRET = "Something else"))
    })
})

test_that("chain_redactors", {
    f1 <- function (x) x * 4
    f2 <- ~ sum(c(., 3))
    f12 <- chain_redactors(list(f1, f2))
    f21 <- chain_redactors(list(f2, f1))
    expect_equal(f12(5), 23)
    expect_equal(f21(5), 32)
})
