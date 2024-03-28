vis_word_cloud <- function(df_words_count) {
  df_words_count |>
    ggplot() +
    geom_text_wordcloud_area(aes(label = word, size = n)) +
    scale_size_area(max_size = 50) +
    theme_void()
}
