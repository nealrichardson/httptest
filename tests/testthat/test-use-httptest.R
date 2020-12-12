test_add_to_desc <- function(str, msg = "Adding 'httptest' to Suggests") {
  f <- tempfile()
  cat(str, file = f)
  expect_message(add_httptest_to_desc(f), msg)
  setNames(read.dcf(f, keep.white = "Suggests")[, "Suggests"], NULL)
}

test_that("add to desc adds Suggests if not present", {
  expect_identical(test_add_to_desc("Title: Foo"), "httptest")
})

test_that("add to desc adds Suggests if present but empty", {
  expect_identical(test_add_to_desc("Suggests:"), "httptest")
})

test_that("add to desc adds Suggests inline", {
  expect_identical(test_add_to_desc("Suggests: pkg"), "httptest, pkg")
  expect_identical(
    test_add_to_desc("Suggests: pkg, alpha (>= 2.0.0)"),
    "alpha (>= 2.0.0), httptest, pkg"
  )
})

desc_suggests_one_multiline <- "Title: Foo
Suggests:
    pkg
"
desc_suggests_two_multiline <- "Title: Foo
Suggests:
    pkg,
    alpha (>= 2.0.0)
"
desc_suggests_two_uneven <- "Title: Foo
Suggests: pkg,
    alpha (>= 2.0.0)
"

test_that("add to desc adds Suggests multiline", {
  expect_identical(
    test_add_to_desc(desc_suggests_one_multiline),
    "\n    httptest,\n    pkg"
  )
  expect_identical(
    test_add_to_desc(desc_suggests_two_multiline),
    "\n    alpha (>= 2.0.0),\n    httptest,\n    pkg"
  )
  expect_identical(
    test_add_to_desc(desc_suggests_two_uneven),
    "alpha (>= 2.0.0),\n    httptest,\n    pkg"
  )
})

test_that("add to desc doesn't add if already present", {
  expect_identical(test_add_to_desc("Suggests: httptest", msg = NA), "httptest")
  expect_identical(
    test_add_to_desc("Suggests: pkg, httptest", msg = NA),
    "pkg, httptest"
  )
})

expect_added_to_setup <- function(str, msg = "Adding library\\(httptest\\)") {
  f <- tempfile()
  cat(str, file = f)
  expect_message(add_httptest_to_setup(f), msg)
  expect_true(any(grepl("library(httptest)", readLines(f), fixed = TRUE)))
}

test_that("add to setup creates file if doesn't exist", {
  f <- tempfile()
  expect_false(file.exists(f))
  testthat_transition(
    expect_message(add_httptest_to_setup(f), "Creating"),
    expect_message(
      expect_message(add_httptest_to_setup(f), "Creating"),
      "Adding library\\(httptest\\) to"
    )
  )
  expect_identical(readLines(f), "library(httptest)")
})

test_that("add to setup adds", {
  expect_added_to_setup("")
  expect_added_to_setup("library(pkg)\n")
})

test_that("add to setup doesn't duplicate", {
  expect_added_to_setup("library(httptest)\n", msg = NA)
})

test_that("use_httptest integration test", {
  testpkg <- tempfile()
  dir.create(testpkg)
  expect_error(use_httptest(testpkg), "is not an R package directory")

  desc <- file.path(testpkg, "DESCRIPTION")
  cat("Title: Foo\n", file = desc)
  setup <- file.path(testpkg, "tests", "testthat", "setup.R")
  testthat_transition(
    expect_message(use_httptest(testpkg), "Adding 'httptest' to Suggests"),
    expect_message(
      expect_message(
        expect_message(
          use_httptest(testpkg),
          "Adding 'httptest' to Suggests"
        ),
        "Creating "
      ),
      "Adding library\\(httptest\\) to "
    )
  )
  expect_identical(readLines(desc), c("Title: Foo", "Suggests: httptest"))
  expect_identical(readLines(setup), "library(httptest)")
  # It does nothing if you the package already uses httptest
  expect_message(use_httptest(testpkg), NA)
})
