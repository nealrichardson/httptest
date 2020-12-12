#' Use 'httptest' in your tests
#'
#' This function adds `httptest` to Suggests in the package DESCRIPTION and
#' loads it in `tests/testthat/setup.R`. Call it once when you're setting up
#' a new package test suite.
#'
#' The function is idempotent: if `httptest` is already added to these files, no
#' additional changes will be made.
#'
#' @param path character path to the package
#' @return Nothing: called for file system side effects.
#' @export
use_httptest <- function(path = ".") {
  if (!("DESCRIPTION" %in% dir(path))) {
    stop(path, " is not an R package directory", call. = FALSE)
  }
  add_httptest_to_desc(file.path(path, "DESCRIPTION"))
  # TODO: could allow setup.r too
  add_httptest_to_setup(file.path(path, "tests", "testthat", "setup.R"))
  invisible()
}

add_httptest_to_desc <- function(file) {
  # Read DESCRIPTION, add httptest to Suggests if not already there

  # Hack to preserve whitespace: read it twice
  desc_fields <- colnames(read.dcf(file))
  desc <- read.dcf(file, keep.white = desc_fields)
  if (!("Suggests" %in% desc_fields)) {
    # Add a column for Suggests
    desc <- cbind(desc, matrix("", ncol = 1, dimnames = list(NULL, "Suggests")))
  }
  if (!grepl("httptest", desc[, "Suggests"])) {
    # Add httptest

    # Parse the list, and try to preserve the whitespace from the original
    suggested_pkgs <- unlist(strsplit(desc[, "Suggests"], ","))
    sep <- sub("^([[:blank:]\n]*).*", "\\1", suggested_pkgs)
    suggested_pkgs <- sort(c(trimws(suggested_pkgs), "httptest"))
    extra_sep <- tail(unique(sep), 1)
    if (length(extra_sep) == 0 || nchar(extra_sep) == 0) {
      extra_sep <- " "
    }
    sep <- c(sep, extra_sep)
    desc[, "Suggests"] <- paste0(sep, suggested_pkgs, collapse = ",")

    # Msg and write
    message("Adding 'httptest' to Suggests in DESCRIPTION")
    write.dcf(desc, file = file, keep.white = desc_fields)
  }
}

add_httptest_to_setup <- function(file) {
  # Create tests/testthat/setup.R if it does not exist

  if (!file.exists(file)) {
    message("Creating ", file)
    message("Adding library(httptest) to ", file)
    mkdir_p(file)
    cat("library(httptest)\n", file = file)
    # Msg and write
  } else {
    setup_lines <- readLines(file)
    if (!any(grepl("library(httptest)", setup_lines, fixed = TRUE))) {
      # Add "library(httptest)" to the top if it's not already there
      setup_lines <- c("library(httptest)", setup_lines)
      # Msg and write
      message("Adding library(httptest) to ", file)
      writeLines(setup_lines, file)
    }
  }
}
