# Idea

Scrape the website of my local football club to get an overview of the
content there.

The CSS selectors were extracted using techniques described in this
[wonderful tutorial](https://github.com/hadley/web-scraping). Mainly
relying on the developer features of your web browser.

If you want to reproduce this analysis, you have to perform the
following steps:

-   Clone the [repository]()
-   Run `renv::restore()`
-   Run `targets::tar_make()`

# Data

The following libraries are used in this analysis:

    library(ggwordcloud)
    library(tarchetypes)
    library(conflicted)
    library(wordcloud)
    library(tidyverse)
    library(tidytext)
    library(distill)
    library(targets)
    library(assertr)
    library(polite)
    library(httr2)
    library(rvest)
    library(fs)

    conflicts_prefer(dplyr::filter)

Define where to look for the data:

    tsg_url <- "https://www.tsg-fussball.de/"

We want to obey the scraping restrictions defined by the host.
Therefore, we introduce ourselves to the host and follow the
restrictions defined in ‘robots.txt’. This can be done using the `bow`
function from the `polite` package:

    tsg_host <- bow(tsg_url)

These are the following for this example:

    ## <polite session> https://www.tsg-fussball.de/
    ##     User-agent: polite R package
    ##     robots.txt: 1 rules are defined for 1 bots
    ##    Crawl delay: 5 sec
    ##   The path is scrapable for this user-agent

Define the path, where the news article of this website can be found:

    news_path <- "aktuelles"

Define the CSS selector, which identifies all elements on the websites
that are links to news articles:

    articles_css <- ".more-link"

We now want to find all news articles on the website:

-   Modify the session path with ‘aktuelles’
-   Scrape the website
-   Look for elements representing article links by searching for CSS
    selector ‘.more-link’

<!-- -->

    news_links <- function(tsg_host, news_path, articles_css) {
      host_news <- nod(tsg_host, path = news_path)

      html <- scrape(host_news)

      rows <- html |>
        html_elements(articles_css)

      rows |>
        html_attr("href") |>
        map(\(x) url_parse(x)) |>
        map_chr("path")
    }

    paths_news <- news_links(tsg_host, news_path, articles_css)

In total we have 418 articles to scrape.

Look at some example paths:

    ## [1] "/2023/12/01/regionalliga-22-in-frankfurt-ein-punkt-fuer-die-moral/"      
    ## [2] "/2021/10/13/regionalliga-offenbacher-kickers-zu-gast/"                   
    ## [3] "/2022/03/14/u23-beendet-hinrunde-auf-platz-5-denis-epstein-im-interview/"
    ## [4] "/2022/09/27/regionalliga-balingen-bei-den-spatzen-2/"                    
    ## [5] "/2023/04/08/regionalliga-tsg-duepiert-primus-ulm/"

We want to extract the content of every article. We are looking for the
following parts of the post by searching for specific CSS expressions:

-   Title defined by ‘.gdlr-blog-title’
-   Lines defined by ‘.avia\_textblock p’

<!-- -->

    news <- function(tsg_host, path_news, title_css, line_css) {
      host_detail <- nod(tsg_host, path_news)
      html_detail <- scrape(host_detail)
      tibble(
        title = html_element(html_detail, title_css) |> html_text2(),
        line = html_elements(html_detail, line_css) |> html_text2(),
        path = path_news)
    }

Apply the function for each path:

    df_news <- map_df(paths_news, \(x) news(tsg_host, x, title_css, line_css))

Applying this function multiple times and obeying the scraping
restriction at the same time, can be quite time-consuming. Therefore, we
defined in the targets pipeline (take a look at ’\_targets.R’), that the
function is executed exactly once per article. This means future runs of
the pipeline will detect if an article is already scraped and only
scrape newly added articles, making future runs of the pipeline much
faster.

Sometimes the content seems to be of solely technical nature. Define a
regular expression to search for these lines

    tech_regex <- "xml"

We now want to extract the words from the content we scraped. Before we
do so with the `unnest_tokens` function from the `tidytext` package, we
exclude some lines that have solely technical content, by searching for
keyword ‘xml’:

    words_raw <- function(df_news, tech_regex) {
      df_news |>
        filter(str_detect(line, tech_regex, negate = TRUE)) |>
        unnest_tokens(word, line)
    }

    df_words_raw <- words_raw(df_news, tech_regex)

Before further analysis of the content, exclude some words that are not
relevant for this analysis:

-   German stopwords
-   English stopwords
-   Words that contain solely numeric characters

<!-- -->

    words <- function(df_words_raw) {
      df_words_raw |>
        anti_join(get_stopwords(language = "de"), by = join_by(word)) |>
        anti_join(get_stopwords(language = "en"), by = join_by(word)) |>
        filter(str_detect(word, "^\\d+$", negate = TRUE))
    }

    df_words <- words(df_words_raw)

# Analysis

We want to finish the analysis by creating a wordcloud of the scraped
content.

Define the number of top words:

    top_n_words <- 200L

Count all words and filter for top 200.

    words_count <- function(df_words, top_n_words) {
      df_words |>
        count(word, sort = TRUE) |>
        top_n(top_n_words, wt = n)
    }

    df_words_count <- words_count(df_words, top_n_words)

Create word cloud:

    vis_word_cloud <- function(df_words_count) {
      df_words_count |>
        ggplot() +
        geom_text_wordcloud_area(aes(label = word, size = n)) +
        scale_size_area(max_size = 50) +
        theme_void()
    }

    gg_word_cloud <- vis_word_cloud(df_words_count)

<img src="tsg_word_cloud.png" width="2100" />

And there you go! A complete website scraped in a polite way and
displayed with a nice word cloud. Future updates of this analysis are
quickly done, because only new content is scraped, and old content is
saved in the background. Happy times! Looking forward to further
adventures using the techniques introduced in this blog post.
