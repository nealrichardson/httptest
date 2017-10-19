context("capture_requests")

d <- tempfile()
dl_file <- tempfile()
webp_file <- tempfile()

test_that("We can record a series of requests", {
    skip_if_disconnected()
    capture_requests(path=d, {
        ## <<- assign these so that they're available in the next test_that too
        r1 <<- GET("http://httpbin.org/get")
        r2 <<- GET("http://httpbin.org")
        r3 <<- GET("http://httpbin.org/status/418")
        r4 <<- PUT("http://httpbin.org/put")
        r5 <<- GET("http://httpbin.org/response-headers",
            query=list(`Content-Type`="application/json"))
        r6 <<- GET("http://httpbin.org/anything", config=write_disk(dl_file))
        r7 <<- GET("http://httpbin.org/image/webp", config=write_disk(webp_file))
    })
    expect_identical(sort(dir(d, recursive=TRUE)),
        c("httpbin.org.R", ## it's HTML, so .R
          "httpbin.org/anything.json",
          "httpbin.org/get.json",
          "httpbin.org/image/webp.R",
          "httpbin.org/image/webp.R-FILE", ## The `write_disk` location
          "httpbin.org/put-PUT.json", ## Not a GET, but returns 200
          "httpbin.org/response-headers-ac4928.json",
          "httpbin.org/status/418.R" ## Not 200 response, so .R
          ))

    ## Test the contents of the .R files
    teapot <- source(file.path(d, "httpbin.org/status/418.R"))$value
    expect_is(teapot, "response")
    expect_identical(teapot$status_code, 418L)

    html <- source(file.path(d, "httpbin.org.R"))$value
    expect_true(grepl("</body>", content(html, "text")))
    ## Also test that the .R file itself has text in it
    expect_true(any(grepl("</body>", readLines(file.path(d, "httpbin.org.R")))))
})

test_that("We can then load the mocks it stores", {
    skip_if_disconnected()
    .mockPaths(d) ## Look for mocks in our temp dir
    on.exit(.mockPaths(NULL))

    mock_dl_file <- tempfile()
    mock_webp_file <- tempfile()
    ## Because the place we wrote out the file in our real request might not
    ## naturally be in our mock directory, assume that that file doesn't exist
    ## when we load our mocks.
    content_r6 <- content(r6)
    file.remove(dl_file)
    content_r7 <- content(r7)
    file.remove(webp_file)

    with_mock_API({
        m1 <- GET("http://httpbin.org/get")
        m2 <- GET("http://httpbin.org")
        m3 <- GET("http://httpbin.org/status/418")
        m4 <- PUT("http://httpbin.org/put")
        m5 <- GET("http://httpbin.org/response-headers",
            query=list(`Content-Type`="application/json"))
        m6 <- GET("http://httpbin.org/anything", config=write_disk(mock_dl_file))
        m7 <- GET("http://httpbin.org/image/webp", config=write_disk(mock_webp_file))
    })
    expect_identical(content(m1), content(r1))
    ## Compare the HTML as text because the parsed HTML (XML) object has a
    ## C pointer that is different between the two objects.
    expect_identical(content(m2, "text"), content(r2, "text"))
    expect_identical(content(m3), content(r3))
    expect_identical(content(m4), content(r4))
    expect_identical(content(m5), content(r5))
    expect_identical(content(m6), content_r6)
    expect_identical(content(m7), content_r7)
})

with_mock_API({
    test_that("Recording requests even with the mock API", {
        skip_on_cran() ## They have a broken R-devel build that chokes on these
        d2 <- tempfile()
        capture_requests(path=d2, {
            GET("http://example.com/get/")
        })
        expect_true(setequal(dir(d2, recursive=TRUE),
            c("example.com/get.json")))
        expect_identical(readLines(file.path(d2, "example.com/get.json")),
            readLines("example.com/get.json"))
    })

    test_that("Using simplify=FALSE (and setting .mockPaths)", {
        skip_on_cran() ## They have a broken R-devel build that chokes on these
        d3 <- tempfile()
        .mockPaths(d3)
        on.exit(options(httptest.mock.paths=NULL))
        capture_requests(simplify=FALSE, {
            GET("http://example.com/get/")
        })
        expect_true(setequal(dir(d3, recursive=TRUE),
            c("example.com/get.R")))
        response <- source(file.path(d3, "example.com/get.R"))$value
        expect_is(response, "response")
        expect_identical(content(response),
            content(GET("http://example.com/get/")))
    })

    test_that("Using verbose=TRUE (and .mockPaths)", {
        skip_on_cran() ## They have a broken R-devel build that chokes on these
        d4 <- tempfile()
        .mockPaths(d4)
        on.exit(options(httptest.mock.paths=NULL))
        capture_requests(verbose=TRUE, {
            expect_message(GET("http://example.com/get/"),
                "Writing .*example.com.get.json")
        })
        expect_true(setequal(dir(d4, recursive=TRUE),
            c("example.com/get.json")))
        expect_identical(readLines(file.path(d4, "example.com/get.json")),
            readLines("example.com/get.json"))
    })
})
