Sys.setlocale("LC_COLLATE", "C") ## What CRAN does
set.seed(999)
options(warn=1)

library(httr)

capture_while_mocking <- function (..., path) {
    with_mock_path(path, {
        # We'll write to `path` but read from wherever was set before
        tracer <- quote({
            .mockPaths <- function () getOption("httptest.mock.paths")[-1]
        })
        with_trace("find_mock_file", where=with_mock_api, tracer=tracer,
            expr=capture_requests(...))
    })
}

## from __future__ import ...
if ("Rcmd" %in% ls(envir=asNamespace("tools"))) {
    Rcmd <- tools::Rcmd
} else {
    ## R < 3.3
    Rcmd <- function (args, ...) {
        if (.Platform$OS.type == "windows") {
            system2(file.path(R.home("bin"), "Rcmd.exe"), args, ...)
        } else {
            system2(file.path(R.home("bin"), "R"), c("CMD", args), ...)
        }
    }
}

install_testpkg <- function (pkg) {
    Rcmd(c("INSTALL", pkg))
}
