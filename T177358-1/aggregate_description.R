library(data.table)
library(tidyverse)
library(magrittr)

pluralize <- function(singular, n) {
  plural <- paste0(singular, "s")
  return(c(singular, plural)[(n != 1) + 1])
}

Pluralize <- function(n, singular) {
  return(paste(n, pluralize(singular, n)))
}

wikimedia_color <- c("#CC0000", "#27AA65", "#3366BB")

parsed_description <- data.table::fread('data/commonswiki_20171120_files_description.tsv')

# Total number of files
nrow(parsed_description) #43268565

# Files with infobox
sum(parsed_description$has_infobox == TRUE) # 41796560
sum(parsed_description$has_infobox == TRUE) / nrow(parsed_description) # 96.6%

# Files with description field
sum(parsed_description$has_description_field == TRUE) # 41309028
sum(parsed_description$has_description_field == TRUE) / nrow(parsed_description) # 95.47%

# Process languages column
language_template <- parsed_description[,.(page_id, languages)]
language_template[, languages := gsub("\\[|\\]|\\'| ", '', languages)]
language_template[languages == '', languages := NA]
language_template <- language_template[, list(languages = unlist(strsplit(languages, ","))), by=page_id]

# How many files are in N languages?
n_langs <- language_template[!is.na(languages), .(n_langs = .N), by=page_id]
n_langs %<>%
  mutate(n_langs = if_else(n_langs >= 5, '5+ languages', Pluralize(n_langs, 'language'))) %>%
  group_by(n_langs) %>%
  tally %>%
  rbind(data.frame(n_langs = '0 language', n = sum(is.na(language_template$languages)))) %>%
  mutate(prop = round(n / sum(n) * 100, 2)) 

ggplot2::ggplot(data = n_langs, aes(x = n_langs, y = n)) +
  ggplot2::geom_bar(stat = "identity", position = "dodge", fill = wikimedia_color[2]) +
  ggplot2::scale_y_continuous(labels = polloi::compress) +
  ggplot2::geom_text(aes(label = paste0(n, " (", prop, "%)"), vjust = -0.5), position = position_dodge(width = 1), size = 3) +
  ggplot2::labs(y = "Number of files", x = "Number of language templates (N)", 
                title = "Number of files with N language templates on Commons",
                subtitle = "From data dumps of November 20, 2017") +
  wmf::theme_min()

# How many files are in lang X?
by_langs <- language_template[, .(n_files = .N), by=languages][order(-n_files)]
by_langs[is.na(languages), languages:="No language template"]
top21 <- by_langs$languages[1:21]
by_langs <- by_langs %>%
  mutate(languages = if_else(languages %in% top21, languages, "Other languages")) %>%
  group_by(languages) %>%
  summarize(n_files = sum(n_files)) %>%
  mutate(prop = round(n_files / nrow(parsed_description) * 100, 2))
by_langs$languages <- factor(by_langs$languages, levels = by_langs$languages[order(by_langs$n_files)])

ggplot2::ggplot(data = by_langs, aes(x = languages, y = n_files)) +
  ggplot2::geom_bar(stat = "identity", position = "dodge", fill = wikimedia_color[3]) +
  ggplot2::scale_y_continuous(labels = polloi::compress) +
  ggplot2::geom_text(aes(label = paste0(prop, "% of files"), hjust = -0.1), size = 3) +
  ggplot2::labs(y = "Number of files", x = "Languages", 
                title = "Number of files by language templates on Commons, top 20 languages",
                subtitle = "From data dumps of November 20, 2017") +
  coord_flip() +
  wmf::theme_min()


# Detected Languages
# Process detected languages
detected_languages <- parsed_description[languages == '[]',.(page_id, detected_languages)]
detected_languages[, languages := gsub("\\[|\\]|\\'| ", '', detected_languages)]
detected_languages[, detected_languages:=NULL]
detected_languages[languages == '', languages := NA]
detected_languages <- detected_languages[, list(languages = unlist(strsplit(languages, ","))), by=page_id]

# How many files are in N languages?
n_langs <- detected_languages[!is.na(languages), .(n_langs = .N), by=page_id]
n_langs %<>%
  mutate(n_langs = if_else(n_langs >= 5, '5+ languages', Pluralize(n_langs, 'language'))) %>%
  group_by(n_langs) %>%
  tally %>%
  rbind(data.frame(n_langs = '0 language', n = sum(is.na(detected_languages$languages)))) %>%
  mutate(prop = round(n / nrow(parsed_description) * 100, 2)) 

ggplot2::ggplot(data = n_langs, aes(x = n_langs, y = n)) +
  ggplot2::geom_bar(stat = "identity", position = "dodge", fill = wikimedia_color[2]) +
  ggplot2::scale_y_continuous(labels = polloi::compress) +
  ggplot2::geom_text(aes(label = paste0(n, " (", prop, "% of all files)"), vjust = -0.5), position = position_dodge(width = 1), size = 3) +
  ggplot2::labs(y = "Number of files", x = "Number of detected languages", 
                title = "For Commons files without language templates, the number of files by the number of detected languages",
                subtitle = "From data dumps of November 20, 2017. Using langdetect python package.") +
  wmf::theme_min()

# How many files are in lang X?
by_langs <- detected_languages[, .(n_files = .N), by=languages][order(-n_files)]
by_langs[is.na(languages), languages:="No detected language"]
top21 <- by_langs$languages[1:21]
by_langs <- by_langs %>%
  mutate(languages = if_else(languages %in% top21, languages, "Other languages")) %>%
  group_by(languages) %>%
  summarize(n_files = sum(n_files)) %>%
  mutate(prop = round(n_files / nrow(parsed_description) * 100, 2))
by_langs$languages <- factor(by_langs$languages, levels = by_langs$languages[order(by_langs$n_files)])

ggplot2::ggplot(data = by_langs, aes(x = languages, y = n_files)) +
  ggplot2::geom_bar(stat = "identity", position = "dodge", fill = wikimedia_color[3]) +
  ggplot2::scale_y_continuous(labels = polloi::compress) +
  ggplot2::geom_text(aes(label = paste0(prop, "% of all files"), hjust = -0.1), size = 3) +
  ggplot2::labs(y = "Number of files", x = "Languages", 
                title = "For Commons files without language templates, the number of files by top 20 detected languages",
                subtitle = "From data dumps of November 20, 2017. Using langdetect python package.") +
  coord_flip() +
  wmf::theme_min()

