# Idea

Scrape the website of my local football club to get an overview of the
content there.

The CSS selectors were extracted using techniques described in this
[wonderful tutorial](https://github.com/hadley/web-scraping). Mainly
relying on the developer features of your web browser.

If you want to reproduce this analysis, you have to perform the
following steps:

- Clone the [repository]()
- Run `renv::restore()`
- Run `targets::tar_make()`

# Data

The following libraries are used in this analysis:

    library(ggwordcloud)
    library(tarchetypes)
    library(conflicted)
    library(wordcloud)
    library(tidyverse)
    library(stopwords)
    library(grateful)
    library(tidytext)
    library(distill)
    library(targets)
    library(assertr)
    library(polite)
    library(withr)
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

- Modify the session path with ‘aktuelles’
- Scrape the website
- Look for elements representing article links by searching for CSS
  selector ‘.more-link’

<!-- -->

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

    paths_news <- news_links(tsg_url, news_path, articles_css)

In total we have 702 articles to scrape.

Look at some example paths:

    ## [1] "/2023/07/07/tsg-balingen-und-ezee-energy-setzen-auf-nachhaltigkeit/"
    ## [2] "/2023/05/20/regionalliga-tsg-dank-31-das-zuenglein-an-der-waage/"   
    ## [3] "/2023/11/20/regionalliga-tsg-verliert-02-am-kaiserstuhl/"           
    ## [4] "/2022/04/05/regionalliga-topteams-im-doppelpack/"                   
    ## [5] "/2024/03/09/regionalliga-kapitaen-matze-schmitz-im-interview/"

We want to extract the content of every article. We are looking for the
following parts of the post by searching for specific CSS expressions:

- Title defined by ‘.gdlr-blog-title’
- Lines defined by ‘.avia\_textblock p’

<!-- -->

    news <- function(tsg_url, path_news, title_css, line_css) {
      host_detail <- nod(bow(tsg_url), path_news)
      html_detail <- scrape(host_detail)
      tibble(
        title = html_element(html_detail, title_css) |> html_text2(),
        line = html_elements(html_detail, line_css) |> html_text2(),
        path = path_news
      )
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

- German stopwords
- English stopwords
- Words that contain solely numeric characters

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

Define the number of words we want to display:

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

<img src="tsg_word_cloud.png" alt="" width="2100" />

And there you go! A complete website scraped in a polite way and
displayed with a nice word cloud. Future updates of this analysis are
quickly done, because only new content is scraped, and old content is
saved in the background. Happy times! Looking forward to further
adventures using the techniques introduced in this blog post.

# Acknowledgments

This work was completed using R v. 4.5.2 (R Core Team 2025) and the
following R packages: assertr v. 3.0.1 (Fischetti 2023), distill v. 1.6
(Dervieux et al. 2023), fs v. 1.6.6 (Hester, Wickham, and Csárdi 2025),
ggwordcloud v. 0.6.2 (Le Pennec and Slowikowski 2024), httr2 v. 1.2.2
(Wickham 2025), knitr v. 1.51 (Xie 2014, 2015, 2025), polite v. 0.1.3
(Perepolkin 2023), rmarkdown v. 2.30 (Xie, Allaire, and Grolemund 2018;
Xie, Dervieux, and Riederer 2020; Allaire et al. 2025), shiny v. 1.12.1
(Chang et al. 2025), stopwords v. 2.3 (Benoit, Muhr, and Watanabe 2021),
tarchetypes v. 0.14.0 (Landau 2021a), targets v. 1.12.0 (Landau 2021b),
tidytext v. 0.4.3 (Silge and Robinson 2016), tidyverse v. 2.0.0 (Wickham
et al. 2019), withr v. 3.0.2 (Hester et al. 2024), wordcloud v. 2.6
(Fellows 2018).

Allaire, JJ, Yihui Xie, Christophe Dervieux, Jonathan McPherson, Javier
Luraschi, Kevin Ushey, Aron Atkins, et al. 2025.
*<span class="nocase">rmarkdown</span>: Dynamic Documents for r*.
<https://github.com/rstudio/rmarkdown>.

Benoit, Kenneth, David Muhr, and Kohei Watanabe. 2021.
*<span class="nocase">stopwords</span>: Multilingual Stopword Lists*.
<https://doi.org/10.32614/CRAN.package.stopwords>.

Chang, Winston, Joe Cheng, JJ Allaire, Carson Sievert, Barret Schloerke,
Garrick Aden-Buie, Yihui Xie, et al. 2025.
*<span class="nocase">shiny</span>: Web Application Framework for r*.
<https://doi.org/10.32614/CRAN.package.shiny>.

Dervieux, Christophe, JJ Allaire, Rich Iannone, Alison Presmanes Hill,
and Yihui Xie. 2023. *<span class="nocase">distill</span>: “R Markdown”
Format for Scientific and Technical Writing*.
<https://doi.org/10.32614/CRAN.package.distill>.

Fellows, Ian. 2018. *<span class="nocase">wordcloud</span>: Word
Clouds*. <https://doi.org/10.32614/CRAN.package.wordcloud>.

Fischetti, Tony. 2023. *<span class="nocase">assertr</span>: Assertive
Programming for r Analysis Pipelines*.
<https://doi.org/10.32614/CRAN.package.assertr>.

Hester, Jim, Lionel Henry, Kirill Müller, Kevin Ushey, Hadley Wickham,
and Winston Chang. 2024. *<span class="nocase">withr</span>: Run Code
“With” Temporarily Modified Global State*.
<https://doi.org/10.32614/CRAN.package.withr>.

Hester, Jim, Hadley Wickham, and Gábor Csárdi. 2025.
*<span class="nocase">fs</span>: Cross-Platform File System Operations
Based on “<span class="nocase">libuv</span>”*.
<https://doi.org/10.32614/CRAN.package.fs>.

Landau, William Michael. 2021a.
*<span class="nocase">tarchetypes</span>: Archetypes for Targets*.

———. 2021b. “The Targets r Package: A Dynamic Make-Like
Function-Oriented Pipeline Toolkit for Reproducibility and
High-Performance Computing.” *Journal of Open Source Software* 6 (57):
2959. <https://doi.org/10.21105/joss.02959>.

Le Pennec, Erwan, and Kamil Slowikowski. 2024.
*<span class="nocase">ggwordcloud</span>: A Word Cloud Geom for
“<span class="nocase">ggplot2</span>”*.
<https://doi.org/10.32614/CRAN.package.ggwordcloud>.

Perepolkin, Dmytro. 2023. *<span class="nocase">polite</span>: Be Nice
on the Web*. <https://doi.org/10.32614/CRAN.package.polite>.

R Core Team. 2025. *R: A Language and Environment for Statistical
Computing*. Vienna, Austria: R Foundation for Statistical Computing.
<https://www.R-project.org/>.

Silge, Julia, and David Robinson. 2016.
“<span class="nocase">tidytext</span>: Text Mining and Analysis Using
Tidy Data Principles in r.” *JOSS* 1 (3).
<https://doi.org/10.21105/joss.00037>.

Wickham, Hadley. 2025. *Httr2: Perform HTTP Requests and Process the
Responses*. <https://doi.org/10.32614/CRAN.package.httr2>.

Wickham, Hadley, Mara Averick, Jennifer Bryan, Winston Chang, Lucy
D’Agostino McGowan, Romain François, Garrett Grolemund, et al. 2019.
“Welcome to the <span class="nocase">tidyverse</span>.” *Journal of Open
Source Software* 4 (43): 1686. <https://doi.org/10.21105/joss.01686>.

Xie, Yihui. 2014. “<span class="nocase">knitr</span>: A Comprehensive
Tool for Reproducible Research in R.” In *Implementing Reproducible
Computational Research*, edited by Victoria Stodden, Friedrich Leisch,
and Roger D. Peng. Chapman; Hall/CRC.

———. 2015. *Dynamic Documents with R and Knitr*. 2nd ed. Boca Raton,
Florida: Chapman; Hall/CRC. <https://yihui.org/knitr/>.

———. 2025. *<span class="nocase">knitr</span>: A General-Purpose Package
for Dynamic Report Generation in R*. <https://yihui.org/knitr/>.

Xie, Yihui, J. J. Allaire, and Garrett Grolemund. 2018. *R Markdown: The
Definitive Guide*. Boca Raton, Florida: Chapman; Hall/CRC.
<https://bookdown.org/yihui/rmarkdown>.

Xie, Yihui, Christophe Dervieux, and Emily Riederer. 2020. *R Markdown
Cookbook*. Boca Raton, Florida: Chapman; Hall/CRC.
<https://bookdown.org/yihui/rmarkdown-cookbook>.
