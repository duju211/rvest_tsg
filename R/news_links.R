news_links <- function(tsg_url, news_path, articles_css) {
  host_news <- bow(tsg_url) |>
    nod(path = news_path)

  html <- scrape(host_news)

  rows <- html |>
    html_elements(articles_css)

  rows |>
    html_attr("href") |>
    map(\(x) url_parse(x)) |>
    map_chr("path")
}
