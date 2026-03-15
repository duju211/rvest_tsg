news_date <- function(paths_news) {
  df_news_date <- tibble(path = paths_news) |>
    mutate(
      date = ymd(map_chr(str_split(path, "/"), \(x) str_flatten(x[2:4], "-"))))
  
  df_news_date |>
    assert(not_na, date)
}
