resp <- source("example.com/html.R")$value

test_that("get_content_type handles valid Content-Types, including omitted", {
  expect_identical(resp$headers[["content-type"]], "text/html; charset=utf-8")
  expect_identical(get_content_type(resp), "text/html")
  resp$headers[["content-type"]] <- "application/json"
  expect_identical(get_content_type(resp), "application/json")
  resp$headers[["content-type"]] <- NULL
  expect_identical(get_content_type(resp), "")
})
