structure(list(
  url = "http://httpbin.org/status/204", status_code = 204L,
  headers = structure(list(
    `content-length` = "0", connection = "keep-alive",
    server = "meinheld/0.6.1", date = "Sat, 24 Feb 2018 00:22:11 GMT",
    `content-type` = "text/html; charset=utf-8", `access-control-allow-origin` = "*",
    `access-control-allow-credentials` = "true", `x-powered-by` = "Flask",
    `x-processed-time` = "0", via = "1.1 vegur"
  ), .Names = c(
    "content-length",
    "connection", "server", "date", "content-type", "access-control-allow-origin",
    "access-control-allow-credentials", "x-powered-by", "x-processed-time",
    "via"
  ), class = c("insensitive", "list")), all_headers = list(
    structure(list(status = 204L, version = "HTTP/1.1", headers = structure(list(
      `content-length` = "0", connection = "keep-alive",
      server = "meinheld/0.6.1", date = "Sat, 24 Feb 2018 00:22:11 GMT",
      `content-type` = "text/html; charset=utf-8", `access-control-allow-origin` = "*",
      `access-control-allow-credentials` = "true", `x-powered-by` = "Flask",
      `x-processed-time` = "0", via = "1.1 vegur"
    ), .Names = c(
      "content-length",
      "connection", "server", "date", "content-type", "access-control-allow-origin",
      "access-control-allow-credentials", "x-powered-by", "x-processed-time",
      "via"
    ), class = c("insensitive", "list"))), .Names = c(
      "status",
      "version", "headers"
    ))
  ), cookies = structure(list(
    domain = logical(0),
    flag = logical(0), path = logical(0), secure = logical(0),
    expiration = structure(numeric(0), class = c(
      "POSIXct",
      "POSIXt"
    )), name = logical(0), value = logical(0)
  ), .Names = c(
    "domain",
    "flag", "path", "secure", "expiration", "name", "value"
  ), row.names = integer(0), class = "data.frame"),
  content = charToRaw(""), date = structure(1519431731, class = c(
    "POSIXct",
    "POSIXt"
  ), tzone = "GMT"), times = structure(c(
    0, 4.5e-05,
    4.8e-05, 0.000105, 0.100235, 0.100262
  ), .Names = c(
    "redirect",
    "namelookup", "connect", "pretransfer", "starttransfer",
    "total"
  ))
), .Names = c(
  "url", "status_code", "headers", "all_headers",
  "cookies", "content", "date", "times"
), class = "response")
