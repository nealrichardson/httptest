# Some constants

EXT_TO_CONTENT_TYPE <- list(
    "json"="application/json",
    "xml"="application/xml",
    "csv"="text/csv",
    "html"="text/html",
    "txt"="text/plain",
    "tsv"="text/tab-separated-values"
)

CONTENT_TYPE_TO_EXT <- structure(as.list(names(EXT_TO_CONTENT_TYPE)),
    .Names=unlist(EXT_TO_CONTENT_TYPE, use.names=FALSE))

get_content_type <- function (response) {
    which_header <- tolower(names(response$headers)) == "content-type"
    if (!any(which_header)) {
        # No Content-Type, so /shrug
        return("")
    }
    ct <- response$headers[which_header][[1]]
    # Prune charset or any other parameter appended, and return
    return(sub(";.*$", "", ct))
}
