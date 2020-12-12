structure(list(
  url = "http://httpbin.org/cookies",
  status_code = 200L,
  headers = structure(list(
    connection = "keep-alive", server = "meinheld/0.6.1",
    date = "Thu, 14 Sep 2017 04:42:04 GMT", `content-type` = "application/json",
    `access-control-allow-origin` = "*", `access-control-allow-credentials` = "true",
    `x-powered-by` = "Flask", `x-processed-time` = "0.000869989395142",
    `content-length` = "44", via = "1.1 vegur"
  ), class = c(
    "insensitive",
    "list"
  )),
  all_headers = list(list(
    status = 302L, version = "HTTP/1.1",
    headers = structure(list(
      connection = "keep-alive", server = "meinheld/0.6.1",
      date = "Thu, 14 Sep 2017 04:42:03 GMT", `content-type` = "text/html; charset=utf-8",
      `content-length` = "223", location = "/cookies",
      `set-cookie` = "token=12345; Path=/", `access-control-allow-origin` = "*",
      `access-control-allow-credentials` = "true", `x-powered-by` = "Flask",
      `x-processed-time` = "0.00116801261902", via = "1.1 vegur"
    ), class = c(
      "insensitive",
      "list"
    ))
  ), list(
    status = 200L, version = "HTTP/1.1",
    headers = structure(list(
      connection = "keep-alive", server = "meinheld/0.6.1",
      date = "Thu, 14 Sep 2017 04:42:04 GMT", `content-type` = "application/json",
      `access-control-allow-origin` = "*", `access-control-allow-credentials` = "true",
      `x-powered-by` = "Flask", `x-processed-time` = "0.000869989395142",
      `content-length` = "44", via = "1.1 vegur"
    ), class = c(
      "insensitive",
      "list"
    ))
  )), cookies = structure(list(
    domain = "httpbin.org",
    flag = FALSE, path = "/", secure = FALSE, expiration = structure(Inf, class = c(
      "POSIXct",
      "POSIXt"
    )), name = "token", value = "12345"
  ), row.names = c(
    NA,
    -1L
  ), class = "data.frame"), content = charToRaw("{\n  \"cookies\": {\n    \"token\": \"12345\"\n  }\n}\n"),
  date = structure(1505364124, class = c("POSIXct", "POSIXt"), tzone = "GMT"), times = c(
    redirect = 0.243357, namelookup = 3.6e-05,
    connect = 3.9e-05, pretransfer = 0.000107, starttransfer = 0.116988,
    total = 0.360433
  ), request = structure(list(
    method = "GET",
    url = "http://httpbin.org/cookies/set?token=12345", headers = c(Accept = "application/json, text/xml, application/xml, */*"),
    fields = NULL, options = list(
      useragent = "libcurl/7.54.0 r-curl/2.8.1 httr/1.3.1",
      httpget = TRUE
    ), auth_token = NULL, output = structure(list(), class = c(
      "write_memory",
      "write_function"
    ))
  ), class = "request")
), class = "response")
