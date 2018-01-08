#' @importFrom utils sessionInfo
default_redactor <- function () {
    ## Look for redactor in options
    funcs <- getOption("httptest.redactor")
    if (is.null(funcs)) {
        ## Look for package-defined redactors
        funcs <- find_redactors(names(sessionInfo()$otherPkgs))
        if (length(funcs) == 0) {
            ## If none, provide a default
            funcs <- redact_auth
        }
    }
    return(funcs)
}

find_redactors <- function (packages) {
    ## Given package names, find any redactors put in inst/httptest/redact.R
    funcs <- structure(lapply(packages, get_package_redactor), .Names=packages)
    ## Make sure we have functions
    funcs <- Filter(is.function, funcs)
    return(funcs)
}

get_package_redactor <- function (package) {
    file <- system.file("httptest", "redact.R", package=package)
    if (nchar(file)) {
        ## If file does not exist, it returns ""
        func <- source(file)$value
        if (is.function(func)) {
            return(func)
        }
    }
    return(NULL)
}

prepare_redactor <- function (redactor) {
    ## Message if package redactor(s) are being used, and concatenate if there are several
    if (is.null(redactor)) {
        ## Allow, and make it do nothing
        ## TODO: e2e test NULL redactor
        redactor <- force
    } else if (identical(redactor, redact_auth)) {
        # message("Using default redactor")
    } else if (is.function(redactor)) {
        # message("Using custom redactor")
    } else if (inherits(redactor, "formula")) {
        redactor <- as.redactor(redactor)
    } else if (is.list(redactor)) {
        ## Distinguish length-1 list and named list, message and concat differently
        just_one <- length(redactor) == 1
        noun <- ifelse(just_one, "redactor", "redactors")
        if (is.null(names(redactor))) {
            # msg <- paste("Using", length(redactor), "custom", noun)
        } else {
            msg <- paste("Using", noun, paste(dQuote(names(redactor)), collapse=", "))
            message(msg)
        }
        if (just_one) {
            redactor <- redactor[[1]]
        } else {
            redactor <- chain_redactors(redactor)
        }
    } else {
        stop("Redactor must be a function or list of functions", call.=FALSE)
    }
    return(redactor)
}
