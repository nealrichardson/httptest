default_redactor <- function () {
    ## Look for redactor in options
    funcs <- getOption("httptest.redactor")
    if (is.null(funcs)) {
        ## Look for package-defined redactors
        packages <- get_attached_packages()
        funcs <- find_redactors(packages)
        if (length(funcs) == 0) {
            ## If none, provide a default
            funcs <- redact_auth
        }
        ## Record what packages we considered here
        options(httptest.redactor.packages=packages)
    }
    return(funcs)
}

find_redactors <- function (packages) {
    ## Given package names, find any redactors put in inst/httptest/redact.R
    base_pkgs <- c("base", "compiler", "datasets", "graphics", "grDevices",
                   "grid", "methods", "parallel", "splines", "stats", "stats4",
                   "tcltk", "tools", "utils")
    packages <- setdiff(packages, base_pkgs)
    funcs <- structure(lapply(packages, get_package_redactor), .Names=packages)
    ## Make sure we have functions
    funcs <- Filter(is.function, funcs)
    return(funcs)
}

## TODO: export?
get_package_redactor <- function (package) {
    file <- system.file("httptest", "redact.R", package=package)
    if (nchar(file)) {
        ## If file does not exist, it returns ""
        func <- source(file)$value
        if (is.function(func)) {
            message(paste("Using redactor", dQuote(package)))
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
    ## TODO: document
    ## First, check where we've cached the current one
    out <- getOption("httptest.redactor.current")
    if (is.null(out)) {
        ## Set the default
        out <- prepare_redactor(default_redactor())
        options(httptest.redactor.current=out)
    } else {
        ## See if it needs refreshing
        pkgs <- getOption("httptest.redactor.packages")
        if (!is.null(pkgs)) {
            ## We're using the result of default_redactor(). Let's see if any
            ## new packages have been loaded
            current_packages <- get_attached_packages()
            if (!identical(current_packages, pkgs)) {
                ## Re-evaluate
                funcs <- find_redactors(current_packages)
                if (length(funcs)) {
                    out <- prepare_redactor(funcs)
                } else {
                    out <- redact_auth
                }
                options(
                    httptest.redactor.current=out,
                    httptest.redactor.packages=current_packages
                )
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
