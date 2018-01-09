default_requester <- function (packages=get_attached_packages()) {
    ## Look for package-defined requesters
    func <- requester_from_packages(packages)
    ## Record what packages we considered here
    options(httptest.requester.packages=packages)
    return(func)
}

requester_from_packages <- function (packages) {
    funcs <- find_package_functions(packages, "request.R")
    if (length(funcs)) {
        out <- prepare_redactor(funcs)
    } else {
        ## Default
        out <- force
    }
    return(out)
}

#' Set a request preprocessor
#'
#' @param FUN A function that modifies `request` objects
#' @return Invisibly, the return of the call to `options()`
#' @export
set_requester <- function (FUN) {
    options(httptest.requester=prepare_redactor(FUN))
}

get_current_requester <- function () {
    ## First, check where we've cached the current one
    out <- getOption("httptest.requester")
    if (is.null(out)) {
        ## Set the default
        out <- default_requester()
        options(httptest.requester=out)
    } else {
        ## See if default is based on packages and needs refreshing
        pkgs <- getOption("httptest.requester.packages")
        if (!is.null(pkgs)) {
            ## We're using the result of default_requester(). Let's see if any
            ## new packages have been loaded
            current_packages <- get_attached_packages()
            if (!identical(current_packages, pkgs)) {
                ## Re-evaluate
                out <- default_requester(current_packages)
                options(httptest.requester=out)
            }
        }
    }
    return(out)
}
