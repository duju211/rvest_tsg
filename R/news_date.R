news_date <- function(paths_news) {
  tibble(path = paths_news) |>
    mutate(
      date = ymd(map_chr(str_split(path, "/"), \(x) str_flatten(x[2:4], "-"))))
}
