source("libraries.R")

walk(dir_ls("R"), source)

list(
  tar_target(tsg_url, "https://www.tsg-fussball.de/"),
  tar_target(title_css, ".gdlr-blog-title"),
  tar_target(line_css, ".avia_textblock p"),
  tar_target(word_cloud_path, path("tsg_word_cloud.png"), format = "file"),
  tar_target(news_path, "aktuelles"),
  tar_target(articles_css, ".more-link"),
  tar_target(tech_regex, "xml"),
  tar_target(top_n_words, 200L),

  tar_target(tsg_host, bow(tsg_url), cue = tar_cue("always")),
  tar_target(
    paths_news, news_links(tsg_host, news_path, articles_css),
    cue = tar_cue("always")),
  tar_target(df_news_date, news_date(paths_news)),
  tar_target(
    df_news, news(tsg_host, paths_news, title_css, line_css),
    pattern = map(paths_news), cue = tar_cue("never")),
  tar_target(df_words_raw, words_raw(df_news, tech_regex)),
  tar_target(df_words, words(df_words_raw)),
  tar_target(df_words_count, words_count(df_words, top_n_words)),
  tar_target(gg_word_cloud, vis_word_cloud(df_words_count)),
  tar_target(png_word_cloud, ggsave(word_cloud_path, gg_word_cloud)),

  tar_render(rvest_tsg_blog_post, "rvest_tsg_blog_post.Rmd"),
  tar_render(
    rvest_tsg_readme, "rvest_tsg_blog_post.Rmd",
    output_format = "md_document", output_file = "README.md")
)
