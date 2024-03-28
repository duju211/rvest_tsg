words <- function(df_words_raw) {
  df_words_raw |>
    anti_join(get_stopwords(language = "de"), by = join_by(word)) |>
    anti_join(get_stopwords(language = "en"), by = join_by(word)) |>
    filter(str_detect(word, "^\\d+$", negate = TRUE))
}
