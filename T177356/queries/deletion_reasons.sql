-- Rough approx of reasons why files were deleted in 2017:
SELECT
  MONTH(DATE(LEFT(fa_deleted_timestamp, 8))) AS `month`,
  CASE WHEN fa_minor_mime = 'ogg' THEN 'audio'
       WHEN fa_minor_mime = 'pdf' THEN 'document'
       ELSE fa_major_mime END AS content_type,
  (
    INSTR(LOWER(CONVERT(fa_deleted_reason USING utf8)), 'copyvio') > 0
    OR INSTR(LOWER(CONVERT(fa_deleted_reason USING utf8)), 'copyright') > 0
    OR INSTR(LOWER(CONVERT(fa_deleted_reason USING utf8)), 'trademark') > 0
    OR INSTR(LOWER(CONVERT(fa_deleted_reason USING utf8)), 'logo') > 0
    OR INSTR(LOWER(CONVERT(fa_deleted_reason USING utf8)), 'fair use') > 0
  ) AS copyright_violation,
  (
    INSTR(LOWER(CONVERT(fa_deleted_reason USING utf8)), 'no so') > 0
    OR (
      INSTR(LOWER(CONVERT(fa_deleted_reason USING utf8)), 'no ') > 0
      AND INSTR(LOWER(CONVERT(fa_deleted_reason USING utf8)), 'source') > 0
    )
    OR INSTR(LOWER(CONVERT(fa_deleted_reason USING utf8)), 'unsourced') > 0
  ) AS sourcing_issue,
  INSTR(LOWER(CONVERT(fa_deleted_reason USING utf8)), 'licens') > 0 AS licensing_issue,
  (
    (
      INSTR(LOWER(CONVERT(fa_deleted_reason USING utf8)), 'out') > 0
      OR INSTR(LOWER(CONVERT(fa_deleted_reason USING utf8)), 'project') > 0
    )
    AND INSTR(LOWER(CONVERT(fa_deleted_reason USING utf8)), 'scope') > 0
  ) AS scoping_issue,
  INSTR(CONVERT(fa_deleted_reason USING utf8), 'Old [[User:WeatherBot]] map') > 0 AS old_weatherbot_map,
  -- ^ see: https://commons.wikimedia.org/wiki/User:WeatherBot~commonswiki
  INSTR(CONVERT(fa_deleted_reason USING utf8), 'Category:Unknown') > 0 AS unknown_category,
  (
    INSTR(LOWER(CONVERT(fa_deleted_reason USING utf8)), 'vandal') > 0
    OR INSTR(LOWER(CONVERT(fa_deleted_reason USING utf8)), 'abuse') > 0
  ) AS vandalism,
  (
    INSTR(LOWER(CONVERT(fa_deleted_reason USING utf8)), 'request') > 0
    OR INSTR(LOWER(CONVERT(fa_deleted_reason USING utf8)), 'please delete') > 0
  ) AS requested,
  INSTR(LOWER(CONVERT(fa_deleted_reason USING utf8)), 'otrs') > 0 AS otrs,
  (
    INSTR(LOWER(CONVERT(fa_deleted_reason USING utf8)), 'no ') > 0
    AND INSTR(LOWER(CONVERT(fa_deleted_reason USING utf8)), 'permission') > 0
  ) AS no_permission,
  INSTR(LOWER(CONVERT(fa_deleted_reason USING utf8)), 'duplicat') > 0 AS duplicated,
  INSTR(LOWER(CONVERT(fa_deleted_reason USING utf8)), 'spam') > 0 AS spam,
  INSTR(LOWER(CONVERT(fa_deleted_reason USING utf8)), 'mass del') > 0 AS mass_deletion,
  (
    -- e.g. File is corrupt, empty, or in a [[COM:FT|disallowed format]]
    INSTR(LOWER(CONVERT(fa_deleted_reason USING utf8)), 'corrupt') > 0
    OR INSTR(LOWER(CONVERT(fa_deleted_reason USING utf8)), 'empty') > 0
    OR INSTR(LOWER(CONVERT(fa_deleted_reason USING utf8)), 'disallowed') > 0
  ) AS bad_file,
  (
    INSTR(LOWER(CONVERT(fa_deleted_reason USING utf8)), 'non-free') > 0
    OR INSTR(LOWER(CONVERT(fa_deleted_reason USING utf8)), 'not free') > 0
  ) AS non_free,
  INSTR(LOWER(CONVERT(fa_deleted_reason USING utf8)), 'embedded') > 0 AS embedded_data,
  INSTR(LOWER(CONVERT(fa_deleted_reason USING utf8)), 'mistake') > 0 AS mistake,
  INSTR(LOWER(CONVERT(fa_deleted_reason USING utf8)), 'previously deleted') > 0 AS previously_deleted,
  (
    INSTR(LOWER(CONVERT(fa_deleted_reason USING utf8)), 'reupl') > 0
    OR INSTR(LOWER(CONVERT(fa_deleted_reason USING utf8)), 're-upl') > 0
  ) AS reuploaded,
  (
    -- e.g. Temporary deletion for [[COM:HMS|history cleaning]] or revision suppression
    INSTR(LOWER(CONVERT(fa_deleted_reason USING utf8)), 'temporary delet') > 0
    OR INSTR(LOWER(CONVERT(fa_deleted_reason USING utf8)), 'revision suppression') > 0
  ) AS temporary_deletion,
  (
    -- e.g. Recreation of content deleted per community consensus
    INSTR(LOWER(CONVERT(fa_deleted_reason USING utf8)), 'recreation') > 0
    AND INSTR(LOWER(CONVERT(fa_deleted_reason USING utf8)), 'delet') > 0
    AND INSTR(LOWER(CONVERT(fa_deleted_reason USING utf8)), 'community') > 0
  ) AS recreation,
  (
    INSTR(LOWER(CONVERT(fa_deleted_reason USING utf8)), 'advert') > 0
    OR INSTR(LOWER(CONVERT(fa_deleted_reason USING utf8)), 'promo') > 0
  ) AS advertisement,
  INSTR(LOWER(CONVERT(fa_deleted_reason USING utf8)), 'database error') > 0 database_error,
  COUNT(*) AS files_deleted
FROM commonswiki.filearchive
WHERE fa_deleted_timestamp >= '20170101'
GROUP BY
  `month`, content_type, copyright_violation,
  sourcing_issue, licensing_issue, scoping_issue,
  old_weatherbot_map, unknown_category,
  vandalism, requested, otrs, no_permission,
  duplicated, spam, mass_deletion, bad_file,
  non_free, embedded_data, mistake, previously_deleted,
  reuploaded, temporary_deletion, recreation,
  advertisement, database_error;
