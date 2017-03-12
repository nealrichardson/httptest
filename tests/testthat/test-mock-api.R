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
        })
        test_that("Other verbs error too", {
            expect_PUT(PUT("api/"), "api/")
            expect_PATCH(PATCH("api/"), "api/")
            expect_DELETE(DELETE("api/"), "api/")
        })
        test_that("File download copies the file", {
            f <- tempfile()
            dl <- download.file("api.json", f)
            expect_equal(dl, 0)
            expect_identical(readLines(f), readLines("api.json"))
        })
        test_that("File download if file doesn't exist", {
            f2 <- tempfile()
            expect_error(dl <- download.file("NOTAFILE", f2),
                "DOWNLOAD NOTAFILE")
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
    })
})
