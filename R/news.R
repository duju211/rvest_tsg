news <- function(tsg_host, path_news, title_css, line_css) {
  host_detail <- nod(tsg_host, path_news)
  html_detail <- scrape(host_detail)
  tibble(
    title = html_element(html_detail, title_css) |> html_text2(),
    line = html_elements(html_detail, line_css) |> html_text2(),
    path = path_news)
}
