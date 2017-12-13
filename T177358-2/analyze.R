# Dictionaries
# langs <- dir("~/dictionaries/dictionaries", full.names = TRUE)
# lapply(langs, function(lang) {
#   aff <- sprintf("~/Library/Spelling/%s.aff", gsub("-", "_", basename(lang), fixed = TRUE))
#   dic <- sprintf("~/Library/Spelling/%s.dic", gsub("-", "_", basename(lang), fixed = TRUE))
#   file.copy(file.path(lang, "index.aff"), aff)
#   file.copy(file.path(lang, "index.dic"), dic)
#   return(invisible(NULL))
# })
langs <- sub(".dic", "", dir(path = "~/Library/Spelling", pattern = "*.dic"), fixed = TRUE)
check_dictionaries <- function(x) {
  y <- hunspell::hunspell_parse(x)[[1]]
  counts <- vapply(langs, function(lang) {
    return(sum(hunspell::hunspell_check(y, hunspell::dictionary(lang))))
  }, 1)
  if (all(counts == 0)) return(NA)
  else return(langs[order(counts, decreasing = TRUE)][1])
}

# $ git clone https://github.com/Trey314159/TextCat.git
# tc <- "~/Documents/Code/TextCat (Perl)/text_cat" %>%
#   stringr::str_replace_all(c(" " = "\\\\ ", "\\(" = "\\\\(", "\\)" = "\\\\)"))
tc <- "TextCat/text_cat"
paths <- list(
  query = c(tc = tc, lm = "TextCat/LM-query"),
  full = c(tc = tc, lm = "TextCat/LM")
)

text_cat <- function(x, paths = c(
  tc = "./text_cat",
  lm = NULL
)) {
  if (is.na(x)) return(x)
  cmd <- glue::glue('{paths["tc"]} -d {paths["lm"]} -m 2000 -l "{x}"')
  output <- system(cmd, intern = TRUE)
  return(sub(".*\\t([a-z\\-]{2,8}),[0-9]+.*", "\\1", output))
}
test_string <- "déesse Arthémis"
cld2::detect_language(test_string) # NA
cld3::detect_language(test_string) # NA
text_cat(test_string, paths$full) # "fr"
check_dictionaries(test_string)

refined_events <- readr::read_rds(file.path("data", "refined.rds"))

# Detect languages...
refined_events$safe_query <- trimws(tolower(gsub("[\"`\\]", " ", refined_events$query)))
refined_events$cld2 <- cld2::detect_language(refined_events$safe_query)
refined_events$cld3 <- cld3::detect_language(refined_events$safe_query)
refined_events$textcat <- as.character(NA)
refined_events$tcquery <- as.character(NA)
refined_events$dict <- as.character(NA)

pb <- progress::progress_bar$new(total = sum(!is.na(refined_events$safe_query)))
for (i in 1:nrow(refined_events)) {
  if (!is.na(refined_events$safe_query[i])) {
    pb$tick()
    refined_events$dict[i] <- check_dictionaries(refined_events$safe_query[i])
  }
}; rm(i, pb)
pb <- progress::progress_bar$new(total = sum(!is.na(refined_events$safe_query) & !is.na(refined_events$cld2) & !is.na(refined_events$cld3)))
for (i in 1:nrow(refined_events)) {
  if (
    !is.na(refined_events$safe_query[i]) &&
    !is.na(refined_events$cld2[i]) &&
    !is.na(refined_events$cld3[i])
  ) {
    pb$tick()
    refined_events$textcat[i] <- text_cat(refined_events$safe_query[i], paths$full)
    refined_events$tcquery[i] <- text_cat(refined_events$safe_query[i], paths$query)
  } else {
    next
  }
}; rm(i, pb)

readr::write_rds(refined_events, file.path("data", "analyzed.rds"))

refined_events <- readr::read_rds(file.path("data", "analyzed.rds"))
refined_events$tcquery[refined_events$tcquery == "I don't know. Input is too ambiguous."] <- NA
refined_events$textcat[refined_events$textcat == "I don't know. Input is too ambiguous."] <- NA

language_codes <- ISOcodes::ISO_639_2 %>%
  dplyr::select(code = Alpha_2, language = Name) %>%
  dplyr::filter(!is.na(code)) %>%
  dplyr::arrange(code)
# language_codes <- language_codes$language %>%
#   set_names(language_codes$code)
refined_events$cld2 %<>% sub("([a-z]{2})-.*", "\\1", .)
refined_events$cld3_latin <- grepl("-Latn", refined_events$cld3, fixed = TRUE)
refined_events$cld3 %<>% sub("([a-z]{2})-.*", "\\1", .)
refined_events$dict %<>% sub("([a-z]{2}).*", "\\1", .)
refined_events %<>%
  dplyr::filter(event == "searchResultPage") %>%
  dplyr::select(c(session_id, cld2, cld3, textcat, tcquery)) %>%
  tidyr::gather(algorithm, detected_language, -session_id) %>%
  dplyr::filter(!is.na(detected_language)) %>%
  dplyr::group_by(session_id, detected_language) %>%
  dplyr::tally() %>%
  dplyr::top_n(2, n) %>%
  dplyr::arrange(desc(n), detected_language) %>%
  dplyr::mutate(choice = paste0("choice_", 1:length(n))) %>%
  dplyr::filter(choice %in% c("choice_1", "choice_2")) %>%
  dplyr::select(-n) %>%
  tidyr::spread(choice, detected_language) %>%
  dplyr::left_join(refined_events, ., by = "session_id") %>%
  dplyr::ungroup()

refined_events %>%
  dplyr::filter(event == "searchResultPage", !is.na(choice_1)) %>%
  dplyr::group_by(session_id) %>%
  dplyr::summarize(most_likely = min(choice_1, na.rm = TRUE)) %>%
  dplyr::left_join(language_codes, by = c("most_likely" = "code")) %>%
  dplyr::group_by(language) %>%
  dplyr::tally() %>%
  dplyr::mutate(share = sprintf("%.4f%%", 100 * n / sum(n))) %>%
  dplyr::arrange(desc(n)) %>%
  dplyr::select(-n) %>%
  knitr::kable(format = "markdown")
