words_count <- function(df_words, top_n_words) {
  df_words |>
    count(word, sort = TRUE) |>
    top_n(top_n_words, wt = n)
}
