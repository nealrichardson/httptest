context("Setting different/multiple mock directories")

public({
    test_that(".mockPaths works more or less like .libPaths", {
        expect_identical(.mockPaths(), ".")
        .mockPaths("something else")
        expect_identical(.mockPaths(), c("something else", "."))
        .mockPaths(NULL)
        expect_identical(.mockPaths(), ".")
    })

    with_mock_API({
        test_that("GET with no query, default mock path", {
            b <- GET("api/object1/")
            expect_identical(content(b), list(object=TRUE))
        })
        test_that("GET with query, default mock path", {
            obj <- GET("api/object1/", query=list(a=1))
            expect_json_equivalent(content(obj),
                list(query=list(a=1), mocked="yes"))
        })
        test_that("There is no api/object2/ mock", {
            expect_GET(GET("api/object2/"))
        })
        test_that("File download copies the file", {
            f <- tempfile()
            dl <- download.file("api/object1.json", f)
            expect_equal(dl, 0)
            expect_identical(readLines(f), readLines("api/object1.json"))
        })

        .mockPaths("alt")
        test_that("GET with query, different mock path", {
            obj <- GET("api/object1/", query=list(a=1))
            expect_json_equivalent(content(obj),
                list(query=list(a=1), mocked="twice"))
        })
        test_that("Now there is an api/object2/ mock", {
            obj <- GET("api/object2/")
            expect_identical(content(obj), list(object2=TRUE))
        })
        test_that("If the primary mock dir doesn't have a mock, it passes to next", {
            b <- GET("api/object1/")
            expect_identical(content(b), list(object=TRUE))
        })
        test_that("Failure to find a mock in any dir", {
            expect_GET(GET("api/NOTAFILE/"))
        })
        test_that("File download copies the right file", {
            f <- tempfile()
            dl <- download.file("api/object2.json", f)
            expect_equal(dl, 0)
            expect_identical(readLines(f), readLines("alt/api/object2.json"))
        })

        .mockPaths(NULL)
        test_that("NULL mockPaths resets to default", {
            obj <- GET("api/object1/", query=list(a=1))
            expect_json_equivalent(content(obj),
                list(query=list(a=1), mocked="yes"))
            expect_GET(GET("api/object2/"))
        })
    })
})
