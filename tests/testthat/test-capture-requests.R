context("capture_requests")

d <- tempfile()

test_that("We can record a series of requests", {
    skip_if_disconnected()
    capture_requests(path=d, {
        r1 <<- GET("http://httpbin.org/get")
        r2 <<- GET("http://httpbin.org")
        r3 <<- GET("http://httpbin.org/status/418")
        r4 <<- PUT("http://httpbin.org/put")
        r5 <<- GET("http://httpbin.org/response-headers",
            query=list(`Content-Type`="application/json"))
        utils::download.file("http://httpbin.org/gzip", tempfile(), quiet=TRUE)
    })
    expect_identical(sort(dir(d, recursive=TRUE)),
        c("httpbin.org.R", ## it's HTML, so .R
          "httpbin.org/get.json",
          "httpbin.org/gzip",
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
    with_mock_API({
        m1 <- GET("http://httpbin.org/get")
        m2 <- GET("http://httpbin.org")
        m3 <- GET("http://httpbin.org/status/418")
        m4 <- PUT("http://httpbin.org/put")
        m5 <- GET("http://httpbin.org/response-headers",
            query=list(`Content-Type`="application/json"))
    })
    expect_identical(content(m1), content(r1))
    ## Compare the HTML as text because the parsed HTML (XML) object has a
    ## C pointer that is different between the two objects.
    expect_identical(content(m2, "text"), content(r2, "text"))
    expect_identical(content(m3), content(r3))
    expect_identical(content(m4), content(r4))
    expect_identical(content(m5), content(r5))
})

with_mock_API({
    test_that("Recording requests even with the mock API", {
        d2 <- tempfile()
        capture_requests(path=d2, {
            GET("http://example.com/get/")
            utils::download.file("api/object1.json", tempfile())
        })
        expect_true(setequal(dir(d2, recursive=TRUE),
            c("example.com/get.json", "api/object1.json")))
        expect_identical(readLines(file.path(d2, "example.com/get.json")),
            readLines("example.com/get.json"))
        expect_identical(readLines(file.path(d2, "api/object1.json")),
            readLines("api/object1.json"))
    })

    test_that("Using simplify=FALSE", {
        d3 <- tempfile()
        capture_requests(path=d3, simplify=FALSE, {
            GET("http://example.com/get/")
            utils::download.file("api/object1.json", tempfile())
        })
        expect_true(setequal(dir(d3, recursive=TRUE),
            c("example.com/get.R", "api/object1.json")))
        response <- source(file.path(d3, "example.com/get.R"))$value
        expect_is(response, "response")
        expect_identical(content(response),
            content(GET("http://example.com/get/")))
    })
})
