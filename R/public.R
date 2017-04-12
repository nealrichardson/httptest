#' Test that functions are exported
#'
#' It's easy to forget to document and export a new function. Wrap 'public()'
#' around test blocks to assert that the functions they call
#' are exported (and thus fail if you haven't documented them with @export)
#' @param ... Code to evaluate
#' @return The result of `...` evaluated in the global environment (and not
#' the package environment).
#' @export
public <- function (...) with(globalenv(), ...)

## This exists in the package but not exported so that we can test the behavior
## of the `public` test context
.internalFunction <- function () TRUE
