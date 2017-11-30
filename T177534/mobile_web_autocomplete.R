system("ssh -f -o ExitOnForwardFailure=yes stat1006.eqiad.wmnet -L 3307:analytics-slave.eqiad.wmnet:3306 sleep 10")
library(RMySQL)
con <- dbConnect(MySQL(), host = "127.0.0.1", group = "client", dbname = "log", port = 3307)

query <- "
SELECT
LEFT(timestamp, 8) AS date,
wiki,
event_searchSessionToken,
event_userSessionToken,
CASE event_action WHEN 'click-result' THEN 'clickthroughs'
WHEN 'impression-results' THEN 'Result pages opened'
END AS action,
IF(event_numberOfResults < 1, 'true', 'false') AS zero_result
FROM MobileWebSearch_12054448
WHERE LEFT(timestamp, 6) >= '201711'
AND event_action IN('click-result', 'impression-results')
AND wiki IN ('commonswiki', 'enwiki')
AND INSTR(userAgent, '\"is_bot\": false') > 0;
"
mobile_web_raw <- wmf::mysql_read(query, "log", con)
wmf::mysql_disconnect(con)
save(mobile_web_raw, file = "T177534/data/mobile_web_events_raw_enwiki_commons.RData")

library(tidyverse)
load("T177534/data/mobile_web_events_raw_enwiki_commons.RData")
mobile_web_events <- mobile_web_raw %>%
  mutate(date = lubridate::ymd(date))
mobile_web_ctr_wResult <- mobile_web_events %>%
  filter(zero_result != "true") %>%
  group_by(date, wiki, action) %>%
  summarise(n_events = n()) %>%
  spread(action, n_events) %>%
  mutate(ctr = clickthroughs / `Result pages opened`)
