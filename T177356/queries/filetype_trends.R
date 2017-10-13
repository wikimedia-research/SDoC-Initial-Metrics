system("ssh -f -o ExitOnForwardFailure=yes stat1006.eqiad.wmnet -L 3307:analytics-store.eqiad.wmnet:3306 sleep 10")
library(RMySQL)
con <- dbConnect(MySQL(), host = "127.0.0.1", group = "client", dbname = "commonswiki", port = 3307)

query <- "SELECT
  DATE(LEFT(img_timestamp, 8)) AS `date`,
  SUBSTRING(REGEXP_SUBSTR(LOWER(CONVERT(img_name USING utf8)), '\\\\.([a-z]{3,})$'), 2, 10) AS extension,
  COUNT(*) AS uploads
FROM image
GROUP BY `date`, extension;"

result <- wmf::mysql_read(query, "commonswiki", con)
wmf::mysql_disconnect(con)

library(magrittr)
result$date %<>% lubridate::ymd()
result <- result[result$extension != "", ]

readr::write_csv(result, "T177356/data/filetype_trends.csv")

result %<>%
  dplyr::mutate(extension = dplyr::case_when(
    extension %in% c("jpg", "jpeg") ~ "jpg/jpeg",
    extension %in% c("tif", "tiff") ~ "tif/tiff",
    TRUE ~ extension
  ))
total_uploads <- result %>%
  dplyr::group_by(extension) %>%
  dplyr::summarize(uploads = sum(uploads)) %>%
  dplyr::arrange(desc(uploads))
result %<>%
  dplyr::group_by(extension) %>%
  dplyr::arrange(date) %>%
  dplyr::mutate(total_uploaded = cumsum(uploads)) %>%
  dplyr::ungroup() %>%
  dplyr::mutate(extension = factor(extension, total_uploads$extension))
monthly_uploads <- result %>%
  dplyr::mutate(month = lubridate::floor_date(date, "months")) %>%
  dplyr::group_by(month, extension) %>%
  dplyr::summarize(uploads = sum(uploads)) %>%
  dplyr::ungroup()
monthly_highlights <- monthly_uploads %>%
  dplyr::filter(month < "2017-10-01") %>%
  dplyr::group_by(extension) %>%
  dplyr::top_n(1, uploads)

library(ggplot2)
p <- ggplot(dplyr::filter(monthly_uploads, month < "2017-10-01"), aes(x = month, y = uploads)) +
  geom_line() +
  geom_point(data = monthly_highlights) +
  geom_label(
    data = monthly_highlights,
    aes(
      label = paste(polloi::compress(uploads, 0), "in", format(month, "%b %Y")),
      hjust = "right", vjust = "top"
    ),
    size = 3
  ) +
  scale_y_continuous("Uploads per month", labels = polloi::compress) +
  scale_x_date("Date", date_breaks = "2 years", date_minor_breaks = "1 year", date_labels = "'%y") +
  facet_wrap(~ extension, scales = "free_y") +
  wmf::theme_facet(14, "Open Sans") +
  labs(
    title = "Wikimedia Commons monthly upload counts by file extension",
    subtitle = "Does not include files that have been deleted as of 2017-10-13"
  )
ggsave("T177356/figures/monthly_uploads.png", p, width = 18, height = 9, units = "in", dpi = 150)
p <- ggplot(dplyr::filter(result, date < "2017-10-01"), aes(x = date, y = total_uploaded)) +
  geom_line() +
  scale_y_continuous("Total files uploaded", labels = polloi::compress) +
  scale_x_date("Date", date_breaks = "2 years", date_minor_breaks = "1 year", date_labels = "'%y") +
  facet_wrap(~ extension, scales = "free_y") +
  wmf::theme_facet(14, "Open Sans") +
  labs(
    title = "Wikimedia Commons cumulative upload counts by file extension",
    subtitle = "Does not include files that have been deleted as of 2017-10-13"
  )
ggsave("T177356/figures/cumulative_uploads.png", p, width = 18, height = 9, units = "in", dpi = 150)

# install.packages("treemapify")
# install.packages("viridis")
library(viridis)
library(treemapify)

extension2media <- dplyr::bind_rows(list(
  "image" = dplyr::data_frame(extension = c("jpg/jpeg", "png", "svg", "tif/tiff", "gif", "xcf", "webp")),
  "audio" = dplyr::data_frame(extension = c("flac", "mid", "wav", "ogg", "oga", "opus")),
  "video" = dplyr::data_frame(extension = c("ogv", "webm")),
  "document" = dplyr::data_frame(extension = c("pdf", "djvu"))
), .id = "media")
total_uploads %<>%
  # dplyr::select(-media) %>%
  dplyr::left_join(extension2media, by = "extension")

p <- ggplot(
  dplyr::filter(total_uploads, extension != "jpg/jpeg"),
  aes(area = uploads, fill = log10(uploads + 1), label = extension, subgroup = media)
) +
  geom_treemap(color = "black") +
  geom_treemap_subgroup_border(color = "black") +
  geom_treemap_text(color = "black", place = "topleft", grow = FALSE, min.size = 0) +
  geom_treemap_subgroup_text(
    place = "center", grow = TRUE, alpha = 0.5, color = "black",
    fontface = "italic", min.size = 0
  ) +
  scale_fill_viridis("Total files uploaded (on a logarithmic scale)", labels = function(x) {
    return(polloi::compress(10 ^ x))
  }) +
  guides(fill = guide_colorbar(barwidth = 20, barheight = 1)) +
  wmf::theme_min(14, "Open Sans") +
  labs(
    title = "Treemap of files uploaded to Wikimedia Commons",
    caption = "Due to there being 37M jpg/jpeg files, those extensions have been omitted for visual clarity.",
    subtitle = "These 16 extensions make up 5.7M files that have been uploaded and not deleted"
  )
ggsave("T177356/figures/treemap_uploads.png", p, width = 9, height = 9, units = "in", dpi = 150)

total_uploads %>%
  dplyr::select(media, extension, uploads) %>%
  dplyr::arrange(media, desc(uploads)) %>%
  knitr::kable(format = "markdown")
