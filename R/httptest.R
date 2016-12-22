# Here's a good place to put your top-level package documentation

.onAttach <- function (lib, pkgname="httptest") {
    ## Put stuff here you want to run when your package is loaded
    invisible()
}

## TODO:
# - mock contexts
# - fake response
# - fake api
# - expectations

# fail on request, or message and continue on request; fakeResponse if continue on request
# version of fail/message that overrides GET with fake api
