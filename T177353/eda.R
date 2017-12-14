library(tidyverse)
library(magrittr)

pluralize <- function(n) {
  return(paste(n, c('category', 'categories')[(n > 1) + 1]))
}

wikimedia_color <- c("#CC0000", "#27AA65", "#3366BB")

load("data/category_no_hidden.RData")
category_no_hidden$n_categories[is.na(category_no_hidden$n_categories)] <- 0

sum(category_no_hidden$n_files) # 43631973 files

category_no_hidden %>%
  mutate(n_categories = if_else(n_categories >= 5, '5+ categories', pluralize(n_categories))) %>%
  group_by(n_categories) %>%
  summarize(n_files = sum(n_files)) %>%
  mutate(prop = round(n_files / sum(n_files) * 100, 2)) %>%
  ggplot2::ggplot(aes(x = n_categories, y = n_files)) +
  ggplot2::geom_bar(stat = "identity", position = "dodge", fill = wikimedia_color[2]) +
  ggplot2::scale_y_continuous(labels = polloi::compress) +
  ggplot2::geom_text(aes(label = paste0(n_files, " (", prop, "%)"), vjust = -0.5), position = position_dodge(width = 1), size = 3) +
  ggplot2::labs(y = "Number of files", x = "Number of categories", 
                title = "Number of files by number of categories on Commons",
                subtitle = "Excluding \"needing category\" and hidden categories") +
  wmf::theme_min()

category_no_hidden %>%
  mutate(n_categories = if_else(n_categories >= 5, '5+ categories', pluralize(n_categories))) %>%
  group_by(img_media_type, n_categories) %>%
  summarize(n_files = sum(n_files)) %>%
  mutate(proportion = paste0(round(n_files / sum(n_files) * 100, 2), "%")) %>%
  arrange(img_media_type, n_categories) %>%
  knitr::kable()

