default_redactor <- function (packages=get_attached_packages()) {
    ## Look for package-defined requesters
    func <- redactor_from_packages(packages)
    ## Record what packages we considered here
    options(httptest.redactor.packages=packages)
    return(func)
}

redactor_from_packages <- function (packages) {
    funcs <- find_package_functions(packages, "redact.R")
    if (length(funcs)) {
        out <- prepare_redactor(funcs)
    } else {
        ## Default
        out <- redact_auth
    }
    return(out)
}

find_package_functions <- function (packages, file="redact.R") {
    ## Given package names, find any redactors put in inst/httptest/redact.R
    base_pkgs <- c("base", "compiler", "datasets", "graphics", "grDevices",
                   "grid", "methods", "parallel", "splines", "stats", "stats4",
                   "tcltk", "tools", "utils")
    packages <- setdiff(packages, base_pkgs)
    funcs <- lapply(packages, get_package_function, file)
    ## Make sure we have functions
    funcs <- Filter(is.function, funcs)
    return(funcs)
}

## TODO: export?
get_package_function <- function (package, file="redact.R") {
    func_file <- system.file("httptest", file, package=package)
    if (nchar(func_file)) {
        ## If file does not exist, it returns ""
        func <- source(func_file)$value
        if (is.function(func)) {
            if (isTRUE(getOption("httptest.verbose", TRUE))) {
                message(paste("Using", file, "from", dQuote(package)))
            }
            return(func)
        }
    }
    return(NULL)
}

#' Fetch the active redacting function
#'
#' Called inside [capture_requests()]. If using the default redactor, it checks
#' each time it is called to see if any new packages have been attached, in case
#' there are package redactors in them.
#' @return A redacting function.
#' @export
#' @keywords internal
get_current_redactor <- function () {
    ## First, check where we've cached the current one
    out <- getOption("httptest.redactor")
    if (is.null(out)) {
        ## Set the default
        out <- default_redactor()
        options(httptest.redactor=out)
    } else {
        ## See if default is based on packages and needs refreshing
        pkgs <- getOption("httptest.redactor.packages")
        if (!is.null(pkgs)) {
            ## We're using the result of default_requester(). Let's see if any
            ## new packages have been loaded
            current_packages <- get_attached_packages()
            if (!identical(current_packages, pkgs)) {
                ## Re-evaluate
                out <- default_redactor(current_packages)
                options(httptest.redactor=out)
            }
        }
    }
    return(out)
}

prepare_redactor <- function (redactor) {
    if (is.null(redactor)) {
        ## Allow, and make it do nothing
        redactor <- force
    } else if (inherits(redactor, "formula")) {
        redactor <- as.redactor(redactor)
    } else if (is.list(redactor)) {
        if (length(redactor) == 1) {
            redactor <- redactor[[1]]
        } else {
            redactor <- chain_redactors(redactor)
        }
    }

    if (!is.function(redactor)) {
        stop("Redactor must be a function or list of functions", call.=FALSE)
    }
    return(redactor)
}

get_attached_packages <- function () {
    gsub("^package\\:", "", grep("^package\\:", search(), value=TRUE))
}
