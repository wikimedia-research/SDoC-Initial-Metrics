system("ssh -f -o ExitOnForwardFailure=yes stat1006.eqiad.wmnet -L 3307:analytics-store.eqiad.wmnet:3306 sleep 10")
library(RMySQL)
con <- dbConnect(MySQL(), host = "127.0.0.1", group = "client", dbname = "commonswiki", port = 3307)

query <- "SELECT
  fa_media_type AS media_type,
  (
    INSTR(LOWER(CONVERT(fa_deleted_reason USING utf8)), 'copyvio') > 0
    OR INSTR(LOWER(CONVERT(fa_deleted_reason USING utf8)), 'copyright') > 0
    OR INSTR(LOWER(CONVERT(fa_deleted_reason USING utf8)), 'trademark') > 0
    OR INSTR(LOWER(CONVERT(fa_deleted_reason USING utf8)), 'logo') > 0
    OR INSTR(LOWER(CONVERT(fa_deleted_reason USING utf8)), 'fair use') > 0
    OR INSTR(LOWER(CONVERT(fa_deleted_reason USING utf8)), 'dmca') > 0
    OR INSTR(LOWER(CONVERT(fa_deleted_reason USING utf8)), 'non-free') > 0
    OR INSTR(LOWER(CONVERT(fa_deleted_reason USING utf8)), 'not free') > 0
  ) AS copyright_nonfree,
  fa_timestamp AS ts_uploaded,
  fa_deleted_timestamp AS ts_deleted
FROM filearchive;"
result <- wmf::mysql_read(query, "commonswiki", con)
wmf::mysql_disconnect(con)

library(magrittr)
result$reason <- dplyr::if_else(result$copyright_nonfree == 1, "copyright, logo, or non-free", "other reason")
result$copyright_nonfree <- NULL
result$media_type %<>% tolower
result$ts_uploaded %<>% lubridate::ymd_hms(tz = "UTC")
result$ts_deleted %<>% lubridate::ymd_hms(tz = "UTC")
result$difference <- as.numeric(difftime(result$ts_deleted, result$ts_uploaded, units = "secs"))
result <- result[
  result$difference > 0 & !is.na(result$media_type),
  c("media_type", "reason", "ts_uploaded", "ts_deleted", "difference")
]
result <- result[order(result$media_type, result$reason, result$ts_uploaded), ]

readr::write_csv(
  result[, c("media_type", "reason", "ts_uploaded", "ts_deleted")],
  "T177356/data/time-to-deletion.csv"
)
system("gzip --force T177356/data/time-to-deletion.csv")

median_times <- result %>%
  dplyr::group_by(reason) %>%
  dplyr::summarize(median_time = ceiling(median(difference))) %>%
  dplyr::mutate(median_time = tolower(lubridate::seconds_to_period(median_time))) %>%
  tidyr::spread(reason, median_time) %>%
  unlist

library(ggplot2)
logtime_breaks <- c(1, 60, 60*60, 60*60*24, 60*60*24*7, 60*60*24*28, 60*60*24*365, 60*60*24*365*10)
logtime_labels <- function(breaks) {
  lbls <- breaks %>%
    round %>%
    lubridate::seconds_to_period() %>%
    tolower %>%
    gsub(" ", "", .) %>%
    sub("(.*[a-z])0s$", "\\1", .) %>%
    sub("(.*[a-z])0m$", "\\1", .) %>%
    sub("(.*[a-z])0h$", "\\1", .) %>%
    sub("(.*[a-z])0d$", "\\1", .)
  lbls <- dplyr::case_when(
    lbls == "7d" ~ "1wk",
    lbls == "28d" ~ "1mo",
    lbls == "365d" ~ "1yr",
    lbls == "3650d" ~ "10yrs",
    TRUE ~ lbls
  )
  return(lbls)
}
scale_x_logtime <- function(...) {
  scale_x_log10(..., breaks = logtime_breaks, labels = logtime_labels)
}
scale_y_logtime <- function(...) {
  scale_y_log10(..., breaks = logtime_breaks, labels = logtime_labels)
}
p <- ggplot(
  dplyr::filter(result, !media_type %in% c("unknown", "archive", "text")),
  aes(x = difference, fill = reason)
) +
  geom_density(adjust = 1.5, alpha = 0.5) +
  scale_x_logtime(name = "Time to deletion") +
  facet_wrap(~ media_type, scales = "free_y") +
  wmf::theme_facet(14, "Open Sans") +
  theme(
    panel.grid.minor.x = element_blank(),
    axis.text.y = element_blank(),
    panel.grid.major.y = element_blank(),
    panel.grid.minor.y = element_blank(),
    axis.title.y = element_blank()
  ) +
  labs(
    title = "Distribution of files' time-to-deletion, by media type and reason for deletion",
    subtitle = paste("The median time-to-deletion across all media types is", median_times["copyright, logo, or non-free"], "for copyright-related reasons and", median_times["other reason"], "otherwise"),
    caption = "Most copyright-related deletions happen within 1 day of upload across almost all media types, with the exception of 'drawing' (SVGs)
    A lot of audio files are deleted within 1 minute or 1 week of upload
    Half of all images and PDFs deleted were deleted within 1 month of upload for non-copyright reasons"
  )
ggsave("T177356/figures/time-to-deletion.png", p, width = 18, height = 9, units = "in", dpi = 150)
