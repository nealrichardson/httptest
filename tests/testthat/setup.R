Sys.setlocale("LC_COLLATE", "C") ## What CRAN does
set.seed(999)
options(
    warn=1,
    httptest.debug=FALSE
)

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

with_redactor <- function (x, ...) {
    old <- getOption("httptest.redactor")
    set_redactor(x)
    on.exit(set_redactor(old))
    eval.parent(...)
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

install_testpkg <- function (pkg, lib=tempfile()) {
    dir.create(lib)
    Rcmd(c("INSTALL", "testpkg", paste0("--library=", shQuote(lib))),
        stdout=NULL, stderr=NULL)
    return(lib)
}

skip_on_R_older_than <- function (version) {
    r <- R.Version()
    if (utils::compareVersion(paste(r$major, r$minor, sep="."), version) < 0) {
        skip(paste("Requires R >=", version))
    }
}
