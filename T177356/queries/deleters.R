system("ssh -f -o ExitOnForwardFailure=yes stat1006.eqiad.wmnet -L 3307:analytics-store.eqiad.wmnet:3306 sleep 10")
library(RMySQL)
con <- dbConnect(MySQL(), host = "127.0.0.1", group = "client", dbname = "commonswiki", port = 3307)

query <- "SELECT
  fa_deleted_timestamp,
  fa_deleted_user,
  user_groups.ug_group
FROM filearchive
LEFT JOIN user_groups ON filearchive.fa_deleted_user = user_groups.ug_user;"
result <- wmf::mysql_read(query, "commonswiki", con)
wmf::mysql_disconnect(con)

library(magrittr)
result %<>%
  dplyr::rename(
    ts = fa_deleted_timestamp,
    user_id = fa_deleted_user,
    group = ug_group
  ) %>%
  dplyr::mutate(
    ts = lubridate::ymd_hms(ts),
    # Anonymize:
    user = as.numeric(factor(as.character(user_id)))
  ) %>%
  dplyr::select(-user_id)
deletion_counts <- result %>%
  dplyr::mutate(date = as.Date(ts)) %>%
  dplyr::group_by(user, date) %>%
  dplyr::summarize(
    deletions = n(),
    groups = paste0(group, collapse = ", ")
  )

# New users who've deleted files:
user_counts <- deletion_counts %>%
  dplyr::group_by(user) %>%
  dplyr::summarize(first_date = min(date)) %>%
  dplyr::arrange(first_date) %>%
  dplyr::group_by(first_date) %>%
  dplyr::summarize(new_users = n()) %>%
  dplyr::mutate(deleting_users = cumsum(new_users))

library(ggplot2)
p <- ggplot(user_counts, aes(x = first_date, y = deleting_users)) +
  geom_line() +
  scale_x_date("Date", date_breaks = "1 year", date_labels = "'%y") +
  scale_y_continuous("Users", breaks = seq(0, 600, 100)) +
  wmf::theme_min(14, "Open Sans", panel.grid.minor.x = element_blank()) +
  labs(
    title = "Deleters on Wikimedia Commons",
    subtitle = "Number of users who have deleted at least one file"
  )
ggsave("T177356/figures/cumulative_deleters.png", p, width = 6, height = 3, units = "in", dpi = 150)

p <- deletion_counts %>%
  dplyr::group_by(user) %>%
  dplyr::summarize(deletions = sum(deletions)) %>%
  dplyr::mutate(deletions = as.character(cut(
    deletions,
    breaks = c(0, 10, 50, 100, 500, 1e3, 5e3, 1e4, Inf))
  )) %>%
  dplyr::group_by(deletions) %>%
  dplyr::summarize(users = n()) %>%
  dplyr::mutate(deletions = factor(dplyr::case_when(
    deletions == "(0,10]" ~ "0-10",
    deletions == "(10,50]" ~ "10-50",
    deletions == "(50,100]" ~ "50-100",
    deletions == "(100,500]" ~ "100-500",
    deletions == "(500,1e+03]" ~ "500-1K",
    deletions == "(1e+03,5e+03]" ~ "1K-5K",
    deletions == "(5e+03,1e+04]" ~ "5K-10K",
    deletions == "(1e+04,Inf]" ~ "10K+",
  ), c("0-10", "10-50", "50-100", "100-500", "500-1K", "1K-5K", "5K-10K", "10K+"))) %>%
  ggplot(aes(x = deletions, y = users)) +
  geom_bar(stat = "identity") +
  geom_text(aes(
    label = sprintf("%.0f users", users),
    vjust = "bottom"
  ), nudge_y = 5) +
  wmf::theme_min(14, "Open Sans") +
  labs(
    title = "Users' file deletion activity on Wikimedia Commons",
    subtitle = sprintf(
      "%.0f users who have collectively deleted %s files",
      max(deletion_counts$user),
      polloi::compress(sum(deletion_counts$deletions), 2)
    ),
    x = "Number of files each user has deleted",
    y = "Users who have deleted this many files"
  )
p
ggsave("T177356/figures/deleter_activity.png", p, width = 12, height = 6, units = "in", dpi = 150)
