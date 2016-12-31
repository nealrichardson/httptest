#' Test that objects would generate equivalent JSON
#'
#' Named lists in R are ordered, but they translate to unordered objects in
#' JSON. This test expectation loosens the equality check of two objects to
#' ignore the order of elements in a named list.
#' @param object object to test
#' @param expected expected value
#' @param info extra information to be included in the message
#' @param label character name by which to refer to \code{object} in the test
#' result. Because the tools for deparsing object names that 'testthat' uses
#' aren't exported from that package, the default here is just "object".
#' @param expected.label character same as \code{label} but for \code{expected}
#' @return Invisibly, returns \code{object} for optionally passing to other
#' expectations.
#' @seealso \code{\link[testthat]{expect_equivalent}}
#' @importFrom testthat expect
#' @export
expect_json_equivalent <- function (object, expected, info=NULL,
                                    label="object", expected.label="expected") {
    comp <- json_compare(object, expected, check.attributes=FALSE)
    expect(comp$equal, sprintf("%s not JSON-equivalent to %s.\n%s",
        label, expected.label, comp$message), info = info)
    invisible(object)
}

#' @importFrom testthat compare
json_compare <- function (object, expected, check.attributes=FALSE) {
    compare(object_sort(object), object_sort(expected),
        check.attributes=check.attributes)
}

object_sort <- function (x) {
    if (is.list(x)) {
        x <- as.list(x) ## For S4 subclasses
        if (!is.null(names(x))) {
            x <- x[sort(names(x))]
        }
        return(lapply(x, object_sort))
    }
    return(x)
}
