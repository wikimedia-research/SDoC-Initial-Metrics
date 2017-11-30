system("ssh -f -o ExitOnForwardFailure=yes stat1006.eqiad.wmnet -L 3307:analytics-slave.eqiad.wmnet:3306 sleep 10")
library(RMySQL)
con <- dbConnect(MySQL(), host = "127.0.0.1", group = "client", dbname = "log", port = 3307)

query <- "
SELECT
LEFT(timestamp, 8) AS date,
timestamp,
wiki,
event_uniqueId AS event_id,
event_searchSessionId AS session_id,
event_pageViewId AS page_id,
event_action AS action
FROM TestSearchSatisfaction2_16909631
WHERE wiki IN ('commonswiki', 'enwiki')
AND LEFT(timestamp, 6) >= '201711'
AND INSTR(userAgent, '\"is_bot\": false') > 0
AND event_source = 'autocomplete'
AND event_action IN('searchResultPage', 'click')
AND (event_subTest IS NULL OR event_subTest IN ('null', 'baseline'));
"
autocomplete_events_raw <- wmf::mysql_read(query, "log", con)
wmf::mysql_disconnect(con)
save(autocomplete_events_raw, file = "T177534/data/autocomplete_events_raw_enwiki_commons.RData")

library(tidyverse)

load("T177534/data/autocomplete_events_raw_enwiki_commons.RData")
autocomplete_events <- autocomplete_events_raw
autocomplete_events$timestamp <- as.POSIXct(autocomplete_events$timestamp, format = "%Y%m%d%H%M%S")
autocomplete_events <- autocomplete_events[order(autocomplete_events$event_id, autocomplete_events$timestamp), ]
autocomplete_events <- autocomplete_events[!duplicated(autocomplete_events$event_id, fromLast = TRUE), ]
autocomplete_events <- autocomplete_events[order(autocomplete_events$session_id, autocomplete_events$page_id, autocomplete_events$timestamp), ]
# Remove outliers (see https://phabricator.wikimedia.org/T150539):
serp_counts <- autocomplete_events %>%
  filter(action == "searchResultPage") %>%
  group_by(session_id) %>%
  summarize(SERPs = n())
valid_sessions <- serp_counts$session_id[serp_counts$SERPs < 1000]
autocomplete_events <- autocomplete_events[autocomplete_events$session_id %in% valid_sessions, ]

autocomplete_events$wiki <- ifelse(autocomplete_events$wiki == "enwiki", "English Wikipedia", "Commons")

# CTR = total click/ total serp
ctr_raw <- autocomplete_events %>%
  group_by(wiki, action) %>%
  summarise(n_events = n()) %>%
  spread(action, n_events) %>%
  ungroup %>%
  cbind(
    as.data.frame(binom:::binom.bayes(x = .$click, n = .$searchResultPage, conf.level = 0.95, tol = 1e-10))
  )
p <- autocomplete_events %>%
  mutate(date = lubridate::ymd(date)) %>%
  group_by(date, wiki, action) %>%
  summarise(n_events = n()) %>%
  spread(action, n_events) %>%
  ungroup %>%
  cbind(
    as.data.frame(binom:::binom.bayes(x = .$click, n = .$searchResultPage, conf.level = 0.95, tol = 1e-9))
  ) %>%
  ggplot(aes(x = date, color = wiki, y = mean, ymin = lower, ymax = upper)) +
  geom_hline(data = ctr_raw, aes(yintercept = mean, color = wiki), linetype = "dashed") +
  geom_ribbon(aes(ymin = lower, ymax = upper, fill = wiki), alpha = 0.1, color = NA) +
  geom_line() +
  scale_color_brewer("Group", palette = "Set1") +
  scale_fill_brewer("Group", palette = "Set1") +
  scale_y_continuous("Clickthrough Rate", labels = scales::percent_format()) +
  labs(title = "Daily autocomplete search clickthrough rates on desktop", subtitle = "Dashed line marks the overall clickthrough rate",
       caption = "*clickthrough rates = total clicks / total search result pages.") +
  wmf::theme_min()
ggsave("daily_autocomplete_ctr.png", p, path = fig_path, units = "in", dpi = plot_resolution, height = 6, width = 10, limitsize = FALSE)
rm(p)

# CTR by page_id
ctr_page <- autocomplete_events %>%
  group_by(date, wiki, session_id, page_id) %>%
  summarise(clickthrough = any(action == "click", na.rm = TRUE)) %>%
  group_by(date, wiki) %>%
  summarize(clickthroughs = sum(clickthrough),
            "Result pages opened" = n()) %>%
  mutate(ctr = clickthroughs / `Result pages opened`)
median(ctr_page$ctr[ctr_page$wiki == "enwiki"]) #0.9087734
median(ctr_page$ctr[ctr_page$wiki == "commonswiki"]) #0.8983008
