news_links <- function(tsg_host, news_path, articles_css) {
  host_news <- nod(tsg_host, path = news_path)

  html <- scrape(host_news)

  rows <- html |>
    html_elements(articles_css)

  rows |>
    html_attr("href") |>
    map(url_parse) |>
    map_chr("path")
}
