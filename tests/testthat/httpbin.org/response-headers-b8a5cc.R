structure(list(
  url = "http://httpbin.org/response-headers?Location=http%3A%2F%2Fhttpbin.org%2Fstatus%2F201",
  status_code = 200L, headers = structure(list(
    connection = "keep-alive",
    server = "meinheld/0.6.1", date = "Sat, 24 Feb 2018 00:22:10 GMT",
    `content-type` = "application/json", location = "http://httpbin.org/status/201",
    `access-control-allow-origin` = "*", `access-control-allow-credentials` = "true",
    `x-powered-by` = "Flask", `x-processed-time` = "0", `content-length` = "89",
    via = "1.1 vegur"
  ), .Names = c(
    "connection", "server",
    "date", "content-type", "location", "access-control-allow-origin",
    "access-control-allow-credentials", "x-powered-by", "x-processed-time",
    "content-length", "via"
  ), class = c("insensitive", "list")), all_headers = list(structure(list(
    status = 200L, version = "HTTP/1.1",
    headers = structure(list(
      connection = "keep-alive", server = "meinheld/0.6.1",
      date = "Sat, 24 Feb 2018 00:22:10 GMT", `content-type` = "application/json",
      location = "http://httpbin.org/status/201", `access-control-allow-origin` = "*",
      `access-control-allow-credentials` = "true", `x-powered-by` = "Flask",
      `x-processed-time` = "0", `content-length` = "89",
      via = "1.1 vegur"
    ), .Names = c(
      "connection", "server",
      "date", "content-type", "location", "access-control-allow-origin",
      "access-control-allow-credentials", "x-powered-by", "x-processed-time",
      "content-length", "via"
    ), class = c("insensitive", "list"))
  ), .Names = c("status", "version", "headers"))), cookies = structure(list(
    domain = logical(0), flag = logical(0), path = logical(0),
    secure = logical(0), expiration = structure(numeric(0), class = c(
      "POSIXct",
      "POSIXt"
    )), name = logical(0), value = logical(0)
  ), .Names = c(
    "domain",
    "flag", "path", "secure", "expiration", "name", "value"
  ), row.names = integer(0), class = "data.frame"),
  content = charToRaw("{\n  \"Content-Type\": \"application/json\", \n  \"Location\": \"http://httpbin.org/status/201\"\n}\n"),
  date = structure(1519431730, class = c("POSIXct", "POSIXt"), tzone = "GMT"), times = structure(c(
    0, 3.1e-05, 3.3e-05,
    7.6e-05, 0.091662, 0.091723
  ), .Names = c(
    "redirect", "namelookup",
    "connect", "pretransfer", "starttransfer", "total"
  ))
), .Names = c(
  "url",
  "status_code", "headers", "all_headers", "cookies", "content",
  "date", "times"
), class = "response")
