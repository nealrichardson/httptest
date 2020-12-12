rp <- httr:::request_perform
g <- httr::GET
path <- tempfile()

test_that("start/end_vignette with recording (dir does not exist yet)", {
  start_vignette(path)
  expect_true(identical(rp, httr:::request_perform))
  expect_false(identical(g, httr::GET))
  expect_identical(.mockPaths()[1], file.path(path, "0"))
  # Test that state_change bumps the mockPath
  change_state()
  expect_identical(.mockPaths()[1], file.path(path, "1"))
  expect_identical(.mockPaths()[2], file.path(path, "0"))
  end_vignette()
  expect_true(identical(rp, httr:::request_perform))
  expect_true(identical(g, httr::GET))
  expect_false(any(grepl(path, .mockPaths()[1], fixed = TRUE)))
})

test_that("start/end_vignette with mocking (dir exists)", {
  on.exit(options(httptest.verbose = NULL))
  dir.create(path)
  start_vignette(path)
  expect_false(identical(rp, httr:::request_perform))
  expect_true(identical(g, httr::GET))
  end_vignette()
  expect_true(identical(rp, httr:::request_perform))
  expect_true(identical(g, httr::GET))
})

test_that("start_vignette puts path in vignettes dir, if exists", {
  d <- tempfile()
  dir.create(file.path(d, "vignettes"), recursive = TRUE)
  old <- setwd(d)
  on.exit(setwd(old))

  start_vignette("testing")
  expect_identical(.mockPaths()[1], file.path("vignettes", "testing", "0"))
  end_vignette()
})

test_that("start/end_vignette calls inst/httptest/vignette-start/end.R", {
  lib <- install_testpkg("testpkg")
  library(testpkg, lib.loc = lib)
  on.exit(detach("package:testpkg", unload = TRUE))
  expect_false(getOption("testpkg.start.vignette", FALSE))
  start_vignette(path)
  expect_true(getOption("testpkg.start.vignette"))

  end_vignette()
  expect_false(getOption("testpkg.start.vignette", FALSE))
})

test_that("change_state validation", {
  with_mock_path("foo", {
    expect_error(change_state(), "foo is not valid for change_state()")
  })
})

reset_redactors()
