structure(list(
  url = "http://httpbin.org/basic-auth/user/passwd",
  status_code = 200L, headers = structure(list(
    connection = "keep-alive",
    server = "meinheld/0.6.1", date = "Sun, 17 Sep 2017 04:48:55 GMT",
    `content-type` = "application/json", `access-control-allow-origin` = "*",
    `access-control-allow-credentials` = "true", `x-powered-by` = "Flask",
    `x-processed-time` = "0.000652074813843", `content-length` = "47",
    via = "1.1 vegur"
  ), class = c("insensitive", "list")),
  all_headers = list(list(
    status = 200L, version = "HTTP/1.1",
    headers = structure(list(
      connection = "keep-alive", server = "meinheld/0.6.1",
      date = "Sun, 17 Sep 2017 04:48:55 GMT", `content-type` = "application/json",
      `access-control-allow-origin` = "*", `access-control-allow-credentials` = "true",
      `x-powered-by` = "Flask", `x-processed-time` = "0.000652074813843",
      `content-length` = "47", via = "1.1 vegur"
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
  content = charToRaw("{\n  \"authenticated\": true, \n  \"user\": \"user\"\n}\n"),
  date = structure(1505623735, class = c("POSIXct", "POSIXt"), tzone = "GMT"), times = c(
    redirect = 0, namelookup = 4.4e-05,
    connect = 4.6e-05, pretransfer = 9.4e-05, starttransfer = 0.11323,
    total = 0.113279
  ), request = structure(list(
    method = "GET",
    url = "http://httpbin.org/basic-auth/user/passwd", headers = c(Accept = "application/json, text/xml, application/xml, */*"),
    fields = NULL, options = list(
      useragent = "libcurl/7.54.0 r-curl/2.8.1 httr/1.3.1",
      httpauth = 1, userpwd = "user:passwd", httpget = TRUE
    ),
    auth_token = NULL, output = structure(list(), class = c(
      "write_memory",
      "write_function"
    ))
  ), class = "request")
), class = "response")
