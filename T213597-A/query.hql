USE wmf;
WITH page_creation_timestamps AS (
  -- since page_creation_timestamp in mediawiki_history table is wrong:
  SELECT
    page_id,
    event_timestamp AS upload_timestamp
  FROM mediawiki_history
  WHERE snapshot = '${snapshot}'
    AND wiki_db = 'commonswiki'
    AND event_entity = 'revision'
    AND page_namespace = 6
    AND revision_parent_id = 0
    AND NOT revision_is_identity_revert -- don't count edits that are reverts
    AND NOT revision_is_identity_reverted -- don't count edits that were reverted
    AND NOT revision_is_deleted -- don't counts edits moved to archive table
    AND page_id IS NOT NULL -- don't count deleted files
), fixed_revision_history AS (
  SELECT
    page_creation_timestamps.page_id AS page_id,
    upload_timestamp,
    event_timestamp AS revision_timestamp,
    revision_parent_id,
    revision_text_bytes_diff
  FROM page_creation_timestamps
  LEFT JOIN mediawiki_history ON (
    page_creation_timestamps.page_id = mediawiki_history.page_id
    AND mediawiki_history.snapshot = '${snapshot}'
    AND mediawiki_history.wiki_db = 'commonswiki'
    AND NOT mediawiki_history.revision_is_identity_revert -- don't count edits that are reverts
    AND NOT mediawiki_history.revision_is_identity_reverted -- don't count edits that were reverted
    AND NOT mediawiki_history.revision_is_deleted -- don't counts edits moved to archive table
  )
), summarized_revisions AS (
  SELECT
    page_id, TO_DATE(upload_timestamp) AS creation_date,
    COUNT(1) AS n_edits,
    SUM(IF(revision_parent_id > 0, 1, 0)) as n_later_edits,
    SUM(IF(revision_text_bytes_diff > 0 AND DATEDIFF(revision_timestamp, upload_timestamp) <= 60 AND revision_parent_id > 0, 1, 0)) AS n_additions_2mo
  FROM fixed_revision_history
  GROUP BY page_id, TO_DATE(upload_timestamp)
)
SELECT
  creation_date,
  COUNT(1) AS n_uploaded, -- files uploaded
  SUM(IF(n_later_edits > 0, 1, 0)) AS n_later_edited, -- files whose pages were edited after upload
  SUM(IF(n_additions_2mo > 0, 1, 0)) AS n_added_to_2mo -- files that have had metadata added after creation and in first 2 months
FROM summarized_revisions
GROUP BY creation_date;
