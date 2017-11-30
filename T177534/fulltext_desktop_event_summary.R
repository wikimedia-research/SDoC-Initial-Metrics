fig_path <- file.path("T177534", "figures")
plot_resolution <- 192

# Daily searches
# p <- searches %>%
#   keep_where(wiki == 'Commons') %>%
#   group_by(date) %>%
#   summarize(`All Search sessions` = length(unique(session_id)), `All Searches` = n(), `Searches with Results` = sum(`got same-wiki results`), `Searches with Clicks` = sum(`same-wiki clickthrough`)) %>%
#   tidyr::gather(key = Type, value = count, -date) %>%
#   ggplot(aes(x = date, y = count, colour = Type)) +
#   geom_line(size = 1.2) +
#   scale_x_date(name = "Date") +
#   scale_y_continuous(labels = polloi::compress, name = "Number of Searches") +
#   labs(title = "Daily desktop full-text searches on Commons",
#        subtitle = "Number of all search sessions, all searches, searches with results and searches with clickthrough") +
#   wmf::theme_min()
# ggsave("daily_searches.png", p, path = fig_path, units = "in", dpi = plot_resolution, height = 6, width = 10, limitsize = FALSE)
# rm(p)

# User agents
user_agents <- events %>%
  dplyr::distinct(wiki, session_id, user_agent)
user_agents <- user_agents %>%
  cbind(., purrr::map_df(.$user_agent, ~ wmf::null2na(jsonlite::fromJSON(.x, simplifyVector = FALSE)))) %>%
  mutate(
    browser = paste(browser_family, browser_major),
    os = case_when(
      is.na(os_major) ~ os_family,
      !is.na(os_major) & !is.na(os_minor) ~ paste0(os_family, " ", os_major, ".", os_minor),
      TRUE ~ paste(os_family, os_major)
    )
  )
top_10_oses <- names(head(sort(table(user_agents$os), decreasing = TRUE), 10))
os_summary <- user_agents %>%
  mutate(os = if_else(os %in% top_10_oses, os, "Other OSes")) %>%
  group_by(wiki, os) %>%
  tally %>%
  mutate(Proportion = paste0(scales::percent_format()(n / sum(n)), " (", n, ")")) %>%
  select(-n) %>%
  tidyr::spread(wiki, Proportion, fill = "0.0% (0)") %>%
  ungroup
top_10_browsers <- names(head(sort(table(user_agents$browser), decreasing = TRUE), 10))
browser_summary <- user_agents %>%
  mutate(browser = if_else(browser %in% top_10_browsers, browser, "Other browsers")) %>%
  group_by(wiki, browser) %>%
  tally %>%
  mutate(Proportion = paste0(scales::percent_format()(n / sum(n)), " (", n, ")")) %>%
  select(-n) %>%
  tidyr::spread(wiki, Proportion, fill = "0.0% (0)") %>%
  ungroup

# ZRR
zrr <- searches %>%
  group_by(wiki) %>%
  summarize(zero = sum(!`got same-wiki results`), n_search = n()) %>%
  ungroup %>%
  cbind(
    as.data.frame(binom:::binom.bayes(x = .$zero, n = .$n_search, conf.level = 0.95, tol = 1e-8))
  )
p <-  zrr %>%
  ggplot(aes(x = wiki, y = mean, color = wiki, ymin = lower, ymax = upper)) +
  geom_linerange() +
  geom_label(aes(label = sprintf("%.2f%%", 100 * mean)), show.legend = FALSE) +
  ggplot2::scale_y_continuous(labels = scales::percent_format()) +
  ggplot2::scale_color_brewer(palette = "Set1") +
  ggplot2::labs(x = NULL, color = "Group", y = "Zero Results Rate", title = "Proportion of full-text searches on desktop that did not yield any results", subtitle = "With 95% credible intervals.") +
  wmf::theme_min()
ggsave("zrr_all.png", p, path = fig_path, units = "in", dpi = plot_resolution, height = 6, width = 10, limitsize = FALSE)
rm(p)

# Daily ZRR
p <- searches %>%
  group_by(date, wiki) %>%
  summarize(n_search = n(), zero = sum(!`got same-wiki results`)) %>%
  ungroup %>%
  cbind(
    as.data.frame(binom:::binom.bayes(x = .$zero, n = .$n_search, conf.level = 0.95, tol = 1e-9))
  ) %>%
  ggplot(aes(x = date, color = wiki, y = mean, ymin = lower, ymax = upper)) +
  geom_hline(data = zrr, aes(yintercept = mean, color = wiki), linetype = "dashed") +
  geom_ribbon(aes(ymin = lower, ymax = upper, fill = wiki), alpha = 0.1, color = NA) +
  geom_line() +
  scale_color_brewer("Group", palette = "Set1") +
  scale_fill_brewer("Group", palette = "Set1") +
  scale_y_continuous("Zero Results Rate", labels = scales::percent_format()) +
  labs(title = "Daily full-text search-wise zero results rate on desktop", subtitle = "Dashed line marks the overall zero results rate") +
  wmf::theme_min()
ggsave("daily_zrr.png", p, path = fig_path, units = "in", dpi = plot_resolution, height = 6, width = 10, limitsize = FALSE)
rm(p)

# CTR
ctr <- searches %>%
  keep_where(`got same-wiki results` == TRUE) %>%
  group_by(wiki) %>%
  summarize(n_search = n(), clickthroughs = sum(`same-wiki clickthrough`)) %>%
  ungroup %>%
  cbind(
    as.data.frame(binom:::binom.bayes(x = .$clickthroughs, n = .$n_search, conf.level = 0.95, tol = 1e-9))
  )
p <-  ctr %>%
  ggplot(aes(x = wiki, y = mean, color = wiki, ymin = lower, ymax = upper)) +
  geom_linerange() +
  geom_label(aes(label = sprintf("%.2f%%", 100 * mean)), show.legend = FALSE) +
  ggplot2::scale_y_continuous(labels = scales::percent_format()) +
  ggplot2::scale_color_brewer(palette = "Set1") +
  ggplot2::labs(x = NULL, y = "Clickthrough rate", title = "Desktop full-text search results clickthrough rates", subtitle = "With 95% credible intervals.") +
  wmf::theme_min()
ggsave("ctr_all.png", p, path = fig_path, units = "in", dpi = plot_resolution, height = 6, width = 10, limitsize = FALSE)
rm(p)

# Daily CTR
p <- searches %>%
  keep_where(`got same-wiki results` == TRUE) %>%
  group_by(wiki, date) %>%
  summarize(n_search = n(), clickthroughs = sum(`same-wiki clickthrough`)) %>%
  ungroup %>%
  cbind(
    as.data.frame(binom:::binom.bayes(x = .$clickthroughs, n = .$n_search, conf.level = 0.95, tol = 1e-9))
  ) %>%
  ggplot(aes(x = date, color = wiki, y = mean, ymin = lower, ymax = upper)) +
  geom_hline(data = ctr, aes(yintercept = mean, color = wiki), linetype = "dashed") +
  geom_ribbon(aes(ymin = lower, ymax = upper, fill = wiki), alpha = 0.1, color = NA) +
  geom_line() +
  scale_color_brewer("Group", palette = "Set1") +
  scale_fill_brewer("Group", palette = "Set1") +
  scale_y_continuous("Clickthrough Rate", labels = scales::percent_format()) +
  labs(title = "Daily search-wise full-text clickthrough rates on desktop", subtitle = "Dashed line marks the overall clickthrough rate") +
  wmf::theme_min()
ggsave("daily_ctr.png", p, path = fig_path, units = "in", dpi = plot_resolution, height = 6, width = 10, limitsize = FALSE)
rm(p)

# SERP offset
offset_prop <- serp_offset %>%
  group_by(session_id, search_id) %>%
  summarize(`Any page-turning` = any(offset > 0)) %>%
  dplyr::right_join(searches, by = c("session_id", "search_id")) %>%
  group_by(wiki) %>%
  summarize(page_turn = sum(`Any page-turning`, na.rm = TRUE), n_search = n()) %>%
  ungroup %>%
  cbind(
    as.data.frame(binom:::binom.bayes(x = .$page_turn, n = .$n_search, conf.level = 0.95, tol = 1e-9))
  )
p <- offset_prop %>%
  ggplot(aes(x = wiki, y = mean, color = wiki, ymin = lower, ymax = upper)) +
  geom_linerange() +
  geom_label(aes(label = sprintf("%.2f%%", 100 * mean)), show.legend = FALSE) +
  ggplot2::scale_y_continuous(labels = scales::percent_format()) +
  ggplot2::scale_color_brewer(palette = "Set1") +
  ggplot2::labs(x = NULL, y = "Proportion of searches", title = "Proportion of desktop full-text searches with clicks to see other pages of the search results", subtitle = "With 95% credible intervals.") +
  wmf::theme_min(plot.title = element_text(size=14))
ggsave("serp_offset_all.png", p, path = fig_path, units = "in", dpi = plot_resolution, height = 6, width = 10, limitsize = FALSE)
rm(p)

# Daily offset prop
p <- serp_offset %>%
  group_by(session_id, search_id) %>%
  summarize(`Any page-turning` = any(offset > 0)) %>%
  dplyr::right_join(searches, by = c("session_id", "search_id")) %>%
  group_by(date, wiki) %>%
  summarize(page_turn = sum(`Any page-turning`, na.rm = TRUE), n_search = n()) %>%
  ungroup %>%
  cbind(
    as.data.frame(binom:::binom.bayes(x = .$page_turn, n = .$n_search, conf.level = 0.95, tol = 1e-10))
  ) %>%
  ggplot(aes(x = date, color = wiki, y = mean, ymin = lower, ymax = upper)) +
  geom_hline(data = offset_prop, aes(yintercept = mean, color = wiki), linetype = "dashed") +
  geom_ribbon(aes(ymin = lower, ymax = upper, fill = wiki), alpha = 0.1, color = NA) +
  geom_line() +
  scale_color_brewer("Group", palette = "Set1") +
  scale_fill_brewer("Group", palette = "Set1") +
  scale_y_continuous("Proportion of searches", labels = scales::percent_format()) +
  labs(title = "Proportion of desktop full-text searches with clicks to see other pages of the search results", subtitle = "Dashed line marks the overall proportion") +
  wmf::theme_min(plot.title = element_text(size=13))
ggsave("daily_serp_offset.png", p, path = fig_path, units = "in", dpi = plot_resolution, height = 6, width = 10, limitsize = FALSE)
rm(p)

# Dwell time after clicked
temp <- visitedPages
temp$SurvObj <- with(temp, survival::Surv(dwell_time, status == 2))
fit <- survival::survfit(SurvObj ~ wiki, data = temp)
ggsurv <- survminer::ggsurvplot(
  fit,
  conf.int = TRUE,
  xlab = "T (Dwell Time in seconds)",
  ylab = "Proportion of visits longer than T (P%)",
  surv.scale = "percent",
  color = "wiki",
  palette = "Set1",
  legend = "bottom",
  legend.title = "",
  ggtheme = wmf::theme_min()
)
p <- ggsurv$plot +
  labs(
    title = "Proportion of visited search results last longer than T",
    subtitle = "Full-text search on desktop. With 95% confidence intervals."
  )
ggsave("survival_visitedPages_all.png", p, path = fig_path, units = "in", dpi = plot_resolution, height = 6, width = 10, limitsize = FALSE)
rm(p)

# Load time
# p <- events %>%
#   keep_where(event == "searchResultPage", `some same-wiki results` == TRUE) %>%
#   ggplot(aes(x = load_time)) +
#   scale_x_log10() +
#   geom_density(aes(group = wiki, colour = wiki, fill = wiki), alpha = 0.3) +
#   scale_color_brewer("Group", palette = "Set1") +
#   scale_fill_brewer("Group", palette = "Set1") +
#   labs(x = "Load Time (ms)", y = "Density", title = "Distribution of search result page load time on desktop") +
#   wmf::theme_min()
# ggsave("serp_loadtime_all.png", p, path = fig_path, units = "in", dpi = plot_resolution, height = 6, width = 10, limitsize = FALSE)
# rm(p)
