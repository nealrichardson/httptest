context("start_vignette")

rp <- httr:::request_perform
g <- httr::GET

test_that("start/end_vignette with mocking", {
    start_vignette()
    expect_false(identical(rp, httr:::request_perform))
    expect_true(identical(g, httr::GET))
    end_vignette()
    expect_true(identical(rp, httr:::request_perform))
    expect_true(identical(g, httr::GET))
})

test_that("start/end_vignette with recording", {
    Sys.setenv(RECORD="true")
    on.exit(Sys.setenv(RECORD=""))
    start_vignette()
    expect_true(identical(rp, httr:::request_perform))
    expect_false(identical(g, httr::GET))
    end_vignette()
    expect_true(identical(rp, httr:::request_perform))
    expect_true(identical(g, httr::GET))
})
