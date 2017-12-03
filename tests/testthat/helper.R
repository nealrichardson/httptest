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
        with_trace("findMockFile", where=with_mock_API, tracer=tracer,
            expr=capture_requests(...))
    })
}
