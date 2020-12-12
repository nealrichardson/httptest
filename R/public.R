#' Test that functions are exported
#'
#' It's easy to forget to document and export a new function. Using `testthat`
#' for your test suite makes it even easier to forget because it evaluates your
#' test code inside the package's namespace, so internal, non-exported functions
#' can be accessed. So you might write a new function, get passing tests, and
#' then tell your package users about the function, but when they try to run it,
#' they get `Error: object 'coolNewFunction' not found`.
#'
#' Wrap `public()` around test blocks to assert that the functions they call
#' are exported (and thus fail if you haven't documented them with `@export`
#' or otherwise added them to your package NAMESPACE file).
#'
#' An alternative way to test that your functions are exported from the package
#' namespace is with examples in the documentation, which `R CMD check` runs
#' in the global namespace and would thus fail if the functions aren't exported.
#' However, code that calls remote APIs, potentially requiring specific server
#' state and authentication, may not be viable to run in examples in
#' `R CMD check`. `public()` provides a solution that works for these cases
#' because you can test your namespace exports in the same place where you are
#' testing the code with API mocks or other safe testing contexts.
#' @param ... Code to evaluate
#' @return The result of `...` evaluated in the global environment (and not
#' the package environment).
#' @export
public <- function(...) with(globalenv(), ...)

# This exists in the package but not exported so that we can test the behavior
# of the `public` test context
.internalFunction <- function() TRUE
