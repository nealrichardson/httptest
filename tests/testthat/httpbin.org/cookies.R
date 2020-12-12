structure(list(
  url = "http://httpbin.org/cookies", status_code = 200L,
  headers = structure(list(
    connection = "keep-alive", server = "meinheld/0.6.1",
    date = "Thu, 14 Sep 2017 04:34:50 GMT", `content-type` = "application/json",
    `access-control-allow-origin` = "*", `access-control-allow-credentials` = "true",
    `x-powered-by` = "Flask", `x-processed-time` = "0.000942945480347",
    `content-length` = "44", via = "1.1 vegur"
  ), class = c(
    "insensitive",
    "list"
  )), all_headers = list(list(
    status = 200L, version = "HTTP/1.1",
    headers = structure(list(
      connection = "keep-alive", server = "meinheld/0.6.1",
      date = "Thu, 14 Sep 2017 04:34:50 GMT", `content-type` = "application/json",
      `access-control-allow-origin` = "*", `access-control-allow-credentials` = "true",
      `x-powered-by` = "Flask", `x-processed-time` = "0.000942945480347",
      `content-length` = "44", via = "1.1 vegur"
    ), class = c(
      "insensitive",
      "list"
    ))
  )), cookies = structure(list(
    domain = logical(0),
    flag = logical(0), path = logical(0), secure = logical(0),
    expiration = structure(numeric(0), class = c(
      "POSIXct",
      "POSIXt"
    )), name = logical(0), value = logical(0)
  ), row.names = integer(0), class = "data.frame"),
  content = charToRaw("{\n  \"cookies\": {\n    \"token\": \"12345\"\n  }\n}\n"),
  date = structure(1505363690, class = c("POSIXct", "POSIXt"), tzone = "GMT"),
  times = c(
    redirect = 0, namelookup = 0.123097, connect = 0.34047,
    pretransfer = 0.340592, starttransfer = 0.546105, total = 0.546146
  ),
  request = structure(list(
    method = "GET",
    url = "http://httpbin.org/cookies",
    headers = c(Accept = "application/json, text/xml, application/xml, */*"),
    fields = NULL,
    options = list(
      useragent = "libcurl/7.54.0 r-curl/2.8.1 httr/1.3.1",
      cookie = "token=12345",
      httpget = TRUE
    ),
    auth_token = NULL,
    output = structure(list(), class = c(
      "write_memory",
      "write_function"
    ))
  ), class = "request")
), class = "response")
