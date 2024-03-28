words_raw <- function(df_news, tech_regex) {
  df_news |>
    filter(str_detect(line, tech_regex, negate = TRUE)) |>
    unnest_tokens(word, line)
}
