library(tidyverse)
library(lubridate)

calculate_proportions <- function(x) {
  mutate(
    x,
    p_added = n_later_edited / n_uploaded,
    p_added_2mo = n_added_to_2mo / n_uploaded
  )
}

edit_stats <- read_csv("data/snapshot_2018-12.csv") %>%
  arrange(creation_date) %>%
  mutate(
    year = year(creation_date),
    month = month(creation_date, label = TRUE, abbr = FALSE)
  )

edit_stats %>%
  calculate_proportions %>%
  mutate(p_added_2mo_avg = c(rep(NA, 15), RcppRoll::roll_mean(p_added_2mo, 31), rep(NA, 15))) %>%
  ggplot(aes(x = creation_date)) +
  geom_line(aes(y = p_added_2mo), color = "gray70", alpha = 0.8) +
  geom_line(aes(y = p_added_2mo_avg), color = "gray10") +
  scale_x_date(date_breaks = "1 year", date_labels = "%Y") +
  scale_y_continuous(labels = scales::percent_format()) +
  labs(
    x = "Upload date", y = "Proportion of uploaded files",
    title = "Files that have had metadata added in the first 2 months (60 days)"
  ) +
  wmf::theme_min()

overall_stats <- edit_stats %>%
  select(-c(creation_date, year, month)) %>%
  summarize_all(sum) %>%
  calculate_proportions
overall_stats %>%
  select(n_uploaded, n_added_to_2mo, p_added_2mo) %>%
  mutate_if(function(x) { x <= 1}, function(x) { sprintf("%.3f%%", 100 * x) }) %>%
  mutate_if(is.numeric, prettyNum, big.mark = ",") %>%
  knitr::kable("markdown", col.names = c(
    "Files since 2003",
    "Metadata augmented w/in 1st 2mo (60d)",
    "Proportion"
  ))

as_percent <- function(x, digits = 3) {
  return(sprintf(paste0("%.", digits, "f%%"), 100 * x))
}

monthly_stats <- edit_stats %>%
  select(-creation_date) %>%
  group_by(year, month) %>%
  summarize_all(sum) %>%
  calculate_proportions %>%
  ungroup %>%
  mutate(p_added_2mo_avg = c(rep(NA, 15), RcppRoll::roll_mean(p_added_2mo, 31), rep(NA, 15)))
monthly_stats %>%
  filter(year == 2018) %>%
  mutate(month = paste(month, year)) %>%
  select(month, n_uploaded, n_added_to_2mo, p_added_2mo) %>%
  mutate_at(vars(starts_with("p_")), as_percent) %>%
  mutate_at(vars(starts_with("n_")), prettyNum, big.mark = ",") %>%
  knitr::kable("markdown", col.names = c(
    "Month",
    "Files uploaded that month",
    "Metadata augmented w/in 1st 2mo (60d)",
    "Proportion"
  ))

yearly_stats <- edit_stats %>%
  select(-c(creation_date, month)) %>%
  group_by(year) %>%
  summarize_all(sum) %>%
  calculate_proportions

yearly_stats %>%
  filter(year > 2003) %>%
  select(year, n_uploaded, n_added_to_2mo, p_added_2mo) %>%
  mutate_at(vars(starts_with("p_")), as_percent) %>%
  mutate_at(vars(starts_with("n_")), prettyNum, big.mark = ",") %>%
  knitr::kable("markdown", col.names = c(
    "Year",
    "Files uploaded that year",
    "Metadata augmented w/in 1st 2mo (60d)",
    "Proportion"
  ))

# ggplot(monthly_stats, aes(x = month, y = p_added_2mo, color = factor(year), group = factor(year))) +
#   stat_summary(fun.y = sum, geom = "line") +
#   scale_x_discrete(limits = month.name, labels = month.abb)
