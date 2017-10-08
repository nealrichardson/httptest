context("Mock API")

public({
    with_mock_API({
        test_that("Can load an object and file extension is added", {
            a <- GET("api/")
            expect_identical(content(a), list(value="api/object1/"))
            b <- GET(content(a)$value)
            expect_identical(content(b), list(object=TRUE))
        })
        test_that("GET with query", {
            obj <- GET("api/object1/", query=list(a=1))
            expect_json_equivalent(content(obj),
                list(query=list(a=1), mocked="yes"))
        })
        test_that("GET files that don't exist errors", {
            expect_GET(GET("api/NOTAFILE/"), "api/NOTAFILE/")
            expect_GET(GET("api/NOTAFILE/", query=list(a=1)),
                "api/NOTAFILE/?a=1")
        })
        test_that("POST method reads from correct file", {
            b <- POST("api/object1")
            expect_identical(content(b), list(method="POST"))
            b2 <- POST("api/object1", body = "", content_type_json(),
                    add_headers(Accept = "application/json",
                                "Content-Type" = "application/json"))
            expect_identical(content(b2), list(method="POST"))
        })
        test_that("Request body is appended to mock file path", {
            p <- POST("api/object1", body='{"a":1}', content_type_json(),
                    add_headers(Accept = "application/json",
                                "Content-Type" = "application/json"))
            expect_identical(content(p), list(content=TRUE))
            expect_POST(POST("api/object1", body='{"b":2}', content_type_json(),
                    add_headers(Accept = "application/json",
                                "Content-Type" = "application/json")),
                'api/object1 {"b":2} (api/object1-3e8d9a-POST.json)')
        })
        test_that("Request body and query", {
            expect_PATCH(PATCH("api/object2?d=1", body='{"arg":45}'),
                'api/object2?d=1 {"arg":45} (api/object2-899b0e-3d8d62-PATCH.json)')
        })
        test_that("Other verbs error too", {
            expect_PUT(PUT("api/"), "api/")
            expect_PATCH(PATCH("api/"), "api/")
            expect_POST(POST("api/"), "api/")
            expect_POST(POST("api/", body='{"arg":true}'),
                'api/',
                '{"arg":true}')
            expect_DELETE(DELETE("api/"), "api/")
        })

        test_that("mock API with http:// URL, not file path", {
            expect_GET(GET("http://httpbin.org/get"),
                "http://httpbin.org/get",
                "(httpbin.org/get.json)")
            expect_GET(GET("https://httpbin.org/get"),
                "https://httpbin.org/get",
                "(httpbin.org/get.json)")
            expect_identical(content(GET("http://example.com/get")),
                list(loaded=TRUE))
        })

        test_that("Mocking a GET with more function args (path, auth)", {
            expect_identical(content(GET("http://example.com",
                path="/get",
                add_headers("Content-Type"="application/json"),
                authenticate("d", "d"))),
                list(loaded=TRUE))
        })

        test_that("Mock GET with non-JSON", {
            dick <- GET("http://example.com/html")
            expect_true(grepl("Melville", content(dick, "text")))
        })

        test_that("POST/PUT/etc. with other body types", {
            b2 <- "http://httpbin.org/post"
            expect_POST(POST(b2, body = list(x = "A simple text string")),
                'http://httpbin.org/post',
                'list(x = "A simple text string") ',
                '(httpbin.org/post-97fc23-POST.json)')
            expect_POST(POST(b2, body = list(x = "A simple text string"), encode="form"),
                'http://httpbin.org/post',
                'x=A%20simple%20text%20string ',
                '(httpbin.org/post-aa2999-POST.json)')
            expect_PUT(PUT(b2, body = list(x = "A simple text string")),
                'http://httpbin.org/post',
                'list(x = "A simple text string") ',
                '(httpbin.org/post-97fc23-PUT.json)')
            expect_POST(POST(b2, body=list(x="A simple text string"), encode="json"),
                'http://httpbin.org/post',
                '{"x":"A simple text string"} ',
                '(httpbin.org/post-34199a-POST.json)')
            skip("Need to find a platform-independent way to hash the filename")
            expect_POST(POST(b2, body = list(y = upload_file("helper.R"))),
                'http://httpbin.org/post',
                'list(y = list(path = "',
                normalizePath("helper.R"),
                '", type = "text/plain")) ',
                '(httpbin.org/post-78d84e-POST.json)')
        })

        test_that("Returned (JSON) mock response contains the actual request", {
            a <- GET("api/", add_headers(`X-FakeHeader`="fake_value"))
            expect_true("X-FakeHeader" %in% names(a$request$headers))
        })
    })
})

test_that("buildMockURL file path construction with character URL", {
    # GET (default) method
    file <- buildMockURL("http://www.test.com/api/call")
    expect <- "www.test.com/api/call.json"
    expect_identical(file, expect, label = "Get method without query string")

    # GET method with query in URL
    file <- buildMockURL("http://www.test.com/api/call?q=1")
    expect <- "www.test.com/api/call-a3679d.json"
    expect_identical(file, expect, label = "Get method with query string")

    # POST method
    file <- buildMockURL("http://www.test.com/api/call", method = "POST")
    expect <- "www.test.com/api/call-POST.json"
    expect_identical(file, expect, "POST method without query string")

    # POST method with query in URL
    file <- buildMockURL("http://www.test.com/api/call?q=1", method = "POST")
    expect <- "www.test.com/api/call-a3679d-POST.json"
    expect_identical(file, expect, "POST method with query string")
})

test_that("buildMockURL returns file names that are valid on all R platforms", {
    u <- "https://language.googleapis.com/v1/documents:annotateText/"
    expect_identical(buildMockURL(u),
        "language.googleapis.com/v1/documents-annotateText.json")
})
