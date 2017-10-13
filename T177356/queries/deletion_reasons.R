system("ssh -f -o ExitOnForwardFailure=yes stat1006.eqiad.wmnet -L 3307:analytics-store.eqiad.wmnet:3306 sleep 10")
library(RMySQL)
con <- dbConnect(MySQL(), host = "127.0.0.1", group = "client", dbname = "commonswiki", port = 3307)

query <- paste0(readr::read_lines("T177356/queries/deletion_reasons.sql"), collapse = "\n")
result <- wmf::mysql_read(query, "commonswiki", con)
wmf::mysql_disconnect(con)
readr::write_csv(result, "T177356/data/deletion_reasons.csv")

result$month <- month.name[result$month]
result <- result[, union(c("month", "content_type", "files_deleted"), names(result))]
result$other_reason <- as.integer(unname(apply(result[, -(1:3)], 1, sum)) == 0)

library(magrittr)
tidy_result <- tidyr::gather(result, reason, indicator, -c(month, content_type, files_deleted)) %>%
  dplyr::filter(indicator == 1) %>%
  dplyr::select(-indicator) %>%
  dplyr::mutate(reason = gsub("_", " ", reason, fixed = TRUE)) %>%
  dplyr::group_by(month, content_type, reason) %>%
  dplyr::summarize(files_deleted = sum(files_deleted)) %>%
  dplyr::ungroup() %>%
  dplyr::mutate(reason = dplyr::case_when(
    reason == "bad file" ~ "bad file (corrupted, empty, disallowed format)",
    reason == "recreation" ~ "recreation of content",
    reason == "copyright violation" ~ "copyright/trademark violation or logo"
    TRUE ~ reason
  ))

total_deleted <- result %>%
  dplyr::filter(!content_type %in% c("application", "text")) %>%
  dplyr::group_by(content_type) %>%
  dplyr::summarize(total_deleted = sum(files_deleted))

reasons <- tidy_result %>%
  dplyr::filter(!content_type %in% c("application", "text")) %>%
  dplyr::group_by(content_type, reason) %>%
  dplyr::summarize(files_deleted = sum(files_deleted)) %>%
  dplyr::ungroup() %>%
  dplyr::left_join(total_deleted, by = "content_type") %>%
  dplyr::mutate(
    prop = files_deleted / total_deleted,
    content_type = paste0(content_type, " (", polloi::compress(total_deleted, 2), " deleted files)")
  )

library(ggplot2)
p <- ggplot(reasons, aes(y = prop, x = reason, fill = reason)) +
  geom_bar(stat = "identity") +
  geom_text(aes(label = sprintf(" %.2f%% (%s files)", 100 * prop, polloi::compress(files_deleted, 1)), hjust = "left")) +
  scale_y_continuous(
    "Proportion of files deleted within content type",
    labels = scales::percent_format(), limits = 0:1
  ) +
  facet_wrap(~ content_type) +
  coord_flip() +
  theme(legend.position = "bottom") +
  wmf::theme_facet(14, "Open Sans") +
  labs(
    title = "Approximate breakdown of reasons for files deleted in 2017, by content type",
    subtitle = "Some files included multiple reasons (e.g. no source AND no license)",
    caption = "Due to the variability in what users write as the reason for deletion (including typos), \"other reason\" includes files that have one of the listed reasons"
  )
ggsave("T177356/figures/deletion_reasons.png", p, width = 16, height = 12, units = "in", dpi = 150)
