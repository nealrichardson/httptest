structure(list(
  url = "https://example.com/login/",
  status_code = 204L, headers = structure(list(
    allow = "GET, HEAD, OPTIONS, POST",
    `content-type` = "application/json;charset=utf-8", date = "Thu, 14 Sep 2017 04:27:22 GMT",
    server = "nginx", `set-cookie` = "token=12345; Domain=example.com; Max-Age=31536000; Path=/",
    vary = "Cookie, Accept-Encoding", connection = "keep-alive"
  ), class = c(
    "insensitive",
    "list"
  )), all_headers = list(list(
    status = 204L, version = "HTTP/1.1",
    headers = structure(list(
      allow = "GET, HEAD, OPTIONS, POST",
      `content-type` = "application/json;charset=utf-8",
      date = "Thu, 14 Sep 2017 04:27:22 GMT", server = "nginx",
      `set-cookie` = "token=12345; Domain=example.com; Max-Age=31536000; Path=/",
      vary = "Cookie, Accept-Encoding", connection = "keep-alive"
    ), class = c(
      "insensitive",
      "list"
    ))
  )), cookies = structure(list(
    domain = "example.com",
    flag = TRUE, path = "/", secure = FALSE, expiration = structure(1536899241, class = c(
      "POSIXct",
      "POSIXt"
    )), name = "token", value = "12345"
  ), row.names = c(
    NA,
    -1L
  ), class = "data.frame"), content = raw(0), date = structure(1505363242, class = c(
    "POSIXct",
    "POSIXt"
  ), tzone = "GMT"), times = c(
    redirect = 0, namelookup = 0.115726,
    connect = 0.467124, pretransfer = 1.405551, starttransfer = 2.041081,
    total = 2.041137
  ), request = structure(list(
    method = "POST",
    url = "https://example.com/login/", headers = c(
      Accept = "application/json, text/xml, application/xml, */*",
      `Content-Type` = "application/json", `user-agent` = "libcurl/7.54.0 curl/2.8.1 httr/1.3.1"
    ), fields = NULL, options = list(
      useragent = "libcurl/7.54.0 r-curl/2.8.1 httr/1.3.1",
      post = TRUE, postfieldsize = 46L, postfields = charToRaw('{"username":"password"}'), postredir = 3
    ), auth_token = NULL, output = structure(list(), class = c(
      "write_memory",
      "write_function"
    ))
  ), class = "request")
), class = "response")
