library(magrittr)
library(RMySQL)

system("ssh -f -o ExitOnForwardFailure=yes stat1006.eqiad.wmnet -L 3307:analytics-slave.eqiad.wmnet:3306 sleep 10")
con <- dbConnect(MySQL(), host = "127.0.0.1", group = "client", dbname = "log", port = 3307)

query <- "SELECT
  timestamp,
  event_source AS source,
  event_uniqueId AS event_id,
  event_searchSessionId AS session_id,
  event_pageViewId AS page_id,
  event_query AS query,
  event_action AS event,
  event_position AS position
FROM TestSearchSatisfaction2_16909631
WHERE wiki = 'commonswiki'
  AND timestamp >= '20171201'
  AND INSTR(userAgent, '\"is_bot\": false') > 0
  AND event_source IN('autocomplete', 'fulltext')
  AND event_action IN('searchResultPage', 'click')
  AND (event_subTest IS NULL OR event_subTest IN ('null', 'baseline'));"
events <- wmf::mysql_read(query, "log", con)
wmf::mysql_disconnect(con)

dir.create("data")
readr::write_rds(events, file.path("data", "events.rds"))

events$timestamp %<>% lubridate::ymd_hms()
events$date <- as.Date(events$timestamp)
refined_events <- events %>%
  dplyr::arrange(session_id, event_id) %>%
  dplyr::distinct(session_id, event_id, .keep_all = TRUE) %>%
  dplyr::select(-event_id) %>%
  dplyr::select(date, timestamp, session_id, page_id, dplyr::everything()) %>%
  dplyr::group_by(session_id, page_id, source, event) %>%
  dplyr::top_n(1, dplyr::desc(timestamp)) %>%
  dplyr::ungroup() %>%
  dplyr::mutate(
    query = stringr::str_trim(query),
    query_length = nchar(query, keepNA = TRUE)
  ) %>%
  dplyr::arrange(session_id, timestamp, query_length)
refined_events <- refined_events[!duplicated(refined_events$query, fromLast = TRUE, incomparables = NA), ]

# Process queries:
refined_events %<>% dplyr::arrange(session_id, page_id, query, timestamp)
refined_events$similarity_next <- as.numeric(NA)
pb <- progress::progress_bar$new(total = nrow(refined_events))
for (i in 2:nrow(refined_events)) {
  pb$tick()
  if (
    refined_events$session_id[i - 1] == refined_events$session_id[i] &&
    refined_events$event[i - 1] == "searchResultPage" &&
    refined_events$event[i] == "searchResultPage"
  ) {
    # need this step for comparing whether one query is a subset of the other
    # we actually can't assume which one is going to be the longer of the two
    queries <- c(tolower(refined_events$query[i - 1]), tolower(refined_events$query[i]))
    queries <- queries[order(nchar(queries), decreasing = FALSE)]
    if (grepl(queries[1], queries[2], fixed = TRUE)) {
      refined_events$similarity_next[i - 1] <- 0.999
    } else {
      refined_events$similarity_next[i - 1] <- stringdist::stringsim(queries[1], queries[2], method = "lcs")
    }
  }
}; rm(i, pb)
refined_events %<>% dplyr::arrange(session_id, timestamp, query_length)

bad_sessions <- data.frame(
  session_id = c("014e96f203d38d93jay1qny0"),
  stringsAsFactors = FALSE
)
bad_sessions <- refined_events %>%
  dplyr::group_by(session_id) %>%
  dplyr::summarize(days = as.numeric(difftime(max(timestamp), min(timestamp), units = "days"))) %>%
  dplyr::filter(days > 1) %>%
  dplyr::select(session_id) %>%
  rbind(bad_sessions)
refined_events %<>% dplyr::anti_join(bad_sessions, by = "session_id")

# Remove events with partial queries leading up to final query:
refined_events %<>% dplyr::filter(similarity_next < 0.75 | is.na(similarity_next))
readr::write_rds(refined_events, file.path("data", "refined.rds"))
