context("capture_requests")

d <- tempfile()
dl_file <- tempfile()
webp_file <- tempfile()

test_that("We can record a series of requests (a few ways)", {
    skip_if_disconnected()
    capture_requests(path=d, {
        ## <<- assign these so that they're available in the next test_that too
        r1 <<- GET("http://httpbin.org/get")
        r2 <<- GET("http://httpbin.org")
        r3 <<- GET("http://httpbin.org/status/418")
        r4 <<- PUT("http://httpbin.org/put")
    })
    start_capturing(path=d)
        r5 <<- GET("http://httpbin.org/response-headers",
            query=list(`Content-Type`="application/json"))
        r6 <<- GET("http://httpbin.org/anything", config=write_disk(dl_file))
        r7 <<- GET("http://httpbin.org/image/webp", config=write_disk(webp_file))
        r8 <<- RETRY("GET", "http://httpbin.org/status/202")
    stop_capturing()
    .mockPaths(NULL) ## because start_capturing with path modifies global state
    expect_identical(sort(dir(d, recursive=TRUE)),
        c("httpbin.org.html", ## it's HTML, and we now support that simplified
          "httpbin.org/anything.json",
          "httpbin.org/get.json",
          "httpbin.org/image/webp.R", ## Not a simplifiable format, so .R
          "httpbin.org/image/webp.R-FILE", ## The `write_disk` location
          "httpbin.org/put-PUT.json", ## Not a GET, but returns 200
          "httpbin.org/response-headers-ac4928.json",
          "httpbin.org/status/202.R", ## Not 200 response, so .R
          "httpbin.org/status/418.R" ## Not 200 response, so .R
          ))
    ## Test the contents of the .R files
    teapot <- source(file.path(d, "httpbin.org/status/418.R"))$value
    expect_is(teapot, "response")
    expect_identical(teapot$status_code, 418L)
    ## Make sure that our .html file has HTML
    expect_true(any(grepl("</body>",
        suppressWarnings(readLines(file.path(d, "httpbin.org.html"))))))
})

test_that("We can then load the mocks it stores", {
    skip_if_disconnected()
    ## Look for mocks in our temp dir
    with_mock_path(d, {
        ## Because the place we wrote out the file in our real request might not
        ## naturally be in our mock directory, assume that that file doesn't exist
        ## when we load our mocks.
        content_r6 <<- content(r6)
        file.remove(dl_file)
        content_r7 <<- content(r7)
        file.remove(webp_file)

        mock_dl_file <- tempfile()
        mock_webp_file <- tempfile()
        with_mock_api({
            m1 <- GET("http://httpbin.org/get")
            m2 <- GET("http://httpbin.org")
            m3 <- GET("http://httpbin.org/status/418")
            m4 <- PUT("http://httpbin.org/put")
            m5 <- GET("http://httpbin.org/response-headers",
                query=list(`Content-Type`="application/json"))
            m6 <- GET("http://httpbin.org/anything", config=write_disk(mock_dl_file))
            m7 <- GET("http://httpbin.org/image/webp", config=write_disk(mock_webp_file))
            m8 <- RETRY("GET", "http://httpbin.org/status/202")
        })
    })
    expect_identical(content(m1), content(r1))
    ## Compare the HTML as text because the parsed HTML (XML) object has a
    ## C pointer that is different between the two objects.
    if (.Platform[["OS.type"]] != "windows") {
        ## Windows (on GH actions) is doing something funny here by including \r
        ## when reading from mocks (but not in the r2)
        expect_identical(content(m2, "text"), content(r2, "text"))
    }

    expect_true(grepl("</body>", content(m2, "text")))
    expect_identical(content(m3), content(r3))
    expect_identical(content(m4), content(r4))
    expect_identical(content(m5), content(r5))
    expect_identical(content(m6), content_r6)
    expect_identical(content(m7), content_r7)
    expect_equal(m8$status_code, 202)
})

test_that("write_disk mocks can be reloaded even if the mock directory moves", {
    skip_if_disconnected()
    ## This is an edge case caught because `crunch` package puts fixtures in
    ## `inst/`, so you record to one place but when you read them from the
    ## installed package, it's a different directory.
    d2 <- tempfile()
    dir.create(file.path(d2, "httpbin.org", "image"), recursive=TRUE)
    for (f in c("httpbin.org/image/webp.R", "httpbin.org/image/webp.R-FILE")) {
        file.rename(file.path(d, f), file.path(d2, f))
    }
    with_mock_path(d2, {
        with_mock_api({
            m7b <- GET("http://httpbin.org/image/webp",
                config=write_disk(tempfile()))
        })
    })
    expect_identical(content(m7b), content_r7)
})

with_mock_api({
    d2 <- tempfile()
    test_that("Recording requests even with the mock API", {
        capture_while_mocking(path=d2, {
            GET("http://example.com/get/")
            GET("api/object1/")
            GET("http://httpbin.org/status/204/")
        })
        expect_true(setequal(dir(d2, recursive=TRUE),
            c("example.com/get.json", "api/object1.json", "httpbin.org/status/204.204")))
        expect_identical(readLines(file.path(d2, "example.com/get.json")),
            readLines("example.com/get.json"))
    })

    test_that("Loading 204 response status recorded with simplify=TRUE", {
        original <- GET("http://httpbin.org/status/204/")
        expect_null(content(original))
        expect_length(readLines(file.path(d2, "httpbin.org/status/204.204")),
            0)
        with_mock_path(d2, {
            mocked <- GET("http://httpbin.org/status/204/")
            expect_null(content(mocked))
        }, replace=TRUE)
    })

    d3 <- tempfile()
    test_that("Using simplify=FALSE (and setting .mockPaths)", {
        with_mock_path(d3, {
            capture_while_mocking(simplify=FALSE, {
                GET("http://example.com/get/")
                GET("api/object1/")
                GET("http://httpbin.org/status/204/")
            })
        })
        expect_true(setequal(dir(d3, recursive=TRUE),
            c("example.com/get.R", "api/object1.R", "httpbin.org/status/204.R")))
        response <- source(file.path(d3, "example.com/get.R"))$value
        expect_is(response, "response")
        expect_identical(content(response),
            content(GET("http://example.com/get/")))
    })

    test_that("Recorded JSON is prettified", {
        expect_length(readLines(file.path(d2, "example.com/get.json")),
            3L)
        skip("TODO: prettify when simplify=FALSE")
        response <- readLines(file.path(d3, "api/object1.R"))
    })

    test_that("Using options(httptest.verbose=TRUE) works", {
        d4 <- tempfile()
        old <- options(httptest.verbose=TRUE)
        on.exit(options(old))
        with_mock_path(d4, {
            capture_while_mocking(
                expect_message(
                    GET("http://example.com/get/"),
                    "Writing .*example.com.get.json"
                )
            )
        })
        expect_true(setequal(dir(d4, recursive=TRUE),
            c("example.com/get.json")))
        expect_identical(readLines(file.path(d4, "example.com/get.json")),
            readLines("example.com/get.json"))
    })

    test_that("Request object isn't recorded at all", {
        d5 <- tempfile()
        with_mock_path(d5, {
            capture_while_mocking({
                POST("http://example.com/login", body=list(username="password"),
                    encode="json")
            }, simplify=FALSE)
            no_payload <- source(file.path(d5,
                "example.com", "login-712027-POST.R"))$value
            expect_null(no_payload$request)
            with_mock_api({
                reloaded <- POST("http://example.com/login",
                    body=list(username="password"),
                    encode="json"
                )
            })
            expect_identical(rawToChar(reloaded$request$options[["postfields"]]),
                '{"username":"password"}')
        })
    })
})

test_that("If the httr request function exits with an error, capture_requests warns", {
    skip_on_R_older_than("3.5.0") # IDK why but it fails on travis
    capture_requests({
        expect_warning(
            expect_error(GET(stop("Error!"))),
            "Request errored; no captured response file saved"
        )
    })
})
