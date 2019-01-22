library(tidyverse)
library(lubridate)

calculate_proportions <- function(x) {
  mutate(
    x,
    p_edited = n_edited / n_total,
    p_added = n_added_to / n_total,
    p_added_2mo = n_added_to_2mo / n_total
  )
}

edit_stats <- read_csv("data/snapshot_2018-12_inclusive.csv") %>%
  arrange(creation_date) %>%
  mutate(
    year = year(creation_date),
    month = month(creation_date, label = TRUE, abbr = FALSE)
  )

edit_stats %>%
  calculate_proportions %>%
  mutate(p_added_2mo_avg = c(rep(NA, 15), RcppRoll::roll_mean(p_added_2mo, 31), rep(NA, 15))) %>%
  ggplot(aes(x = creation_date)) +
  geom_line(aes(y = p_added_2mo), color = "gray70") +
  geom_line(aes(y = p_added_2mo_avg), color = "gray10") +
  coord_cartesian(ylim = c(0.999, 1))

overall_stats <- edit_stats %>%
  select(-c(creation_date, year, month)) %>%
  summarize_all(sum) %>%
  calculate_proportions
overall_stats %>%
  select(n_total, n_added_to_2mo, p_added_2mo) %>%
  mutate_if(function(x) { x <= 1}, function(x) { sprintf("%.6f%%", 100 * x) }) %>%
  mutate_if(is.numeric, prettyNum, big.mark = ",") %>%
  knitr::kable("markdown", col.names = c(
    "Files since 2003",
    "Metadata augmented w/in 1st 2mo (60d)",
    "Proportion"
  ))

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
  select(month, n_total, n_added_to_2mo, p_added_2mo) %>%
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
as_percent <- function(x, digits = 6) {
  return(sprintf(paste0("%.", digits, "f%%"), 100 * x))
}
yearly_stats %>%
  filter(year > 2003) %>%
  select(year, n_total, n_added_to_2mo, p_added_2mo) %>%
  mutate_at(vars(starts_with("p_")), as_percent) %>%
  mutate_at(vars(starts_with("n_")), prettyNum, big.mark = ",") %>%
  knitr::kable("markdown", col.names = c(
    "Year",
    "Files uploaded that year",
    "Metadata augmented w/in 1st 2mo (60d)",
    "Proportion"
  ))

ggplot(monthly_stats, aes(x = month, y = p_added_2mo, color = factor(year), group = factor(year))) +
  stat_summary(fun.y = sum, geom = "line") +
  scale_x_discrete(limits = month.name, labels = month.abb) +
  coord_cartesian(ylim = c(0.999, 1))
