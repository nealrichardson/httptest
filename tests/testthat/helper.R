Sys.setlocale("LC_COLLATE", "C") ## What CRAN does
set.seed(999)
options(warn=1)

library(httr)

## Wrap 'public()' around test blocks to assert that the functions they call
## are exported (and thus fail if you haven't documented them with @export)
public <- function (...) with(globalenv(), ...)
