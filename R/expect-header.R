#' @importFrom httr add_headers
#' @importFrom testthat expect_warning
expect_header <- function (...) {
    tracer <- quote({
        # This is borrowed from what happens inside of httr:::request_prepare
        heads <- c(add_headers(Accept = "application/json, text/xml, application/xml, */*"),
            getOption("httr_config"), req)$headers
        for (h in names(heads)) {
            warning(paste(h, heads[h], sep=": "), call.=FALSE)
        }
    })
    # Magically, this seems to trace even in the mocked versions of this
    suppressMessages(trace("request_perform",
        tracer=tracer,
        at=1,
        print=FALSE,
        where=add_headers))
    on.exit({
        suppressMessages(untrace("request_perform", where=add_headers))
    })
    expect_warning(...)
}
