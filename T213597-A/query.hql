WITH summarized_revisions AS (
  SELECT
    page_id, TO_DATE(page_creation_timestamp) AS creation_date,
    COUNT(1) AS n_edits_total, -- not including reverts or reverted
    SUM(IF(revision_text_bytes_diff > 0, 1, 0)) AS n_additions_total,
    SUM(IF(DATEDIFF(event_timestamp, page_creation_timestamp) <= 60, 1, 0)) AS n_edits_2mo,
    SUM(IF(revision_text_bytes_diff > 0 AND DATEDIFF(event_timestamp, page_creation_timestamp) <= 60, 1, 0)) AS n_additions_2mo
  FROM wmf.mediawiki_history
  WHERE snapshot = '2018-12'
    AND wiki_db = 'commonswiki'
    AND event_entity = 'revision'
    AND page_namespace = 6
    AND NOT revision_is_identity_revert -- don't count edits that are reverts
    AND NOT revision_is_identity_reverted -- don't count edits that were reverted
    AND NOT revision_is_deleted -- don't counts edits moved to archive table
    AND page_id IS NOT NULL -- don't count deleted files
  GROUP BY page_id, TO_DATE(page_creation_timestamp)
)
SELECT
  creation_date,
  COUNT(1) AS n_total,
  SUM(IF(n_edits_total > 0, 1, 0)) AS n_edited,
  SUM(IF(n_additions_total > 0, 1, 0)) AS n_added_to,
  SUM(IF(n_edits_2mo > 0, 1, 0)) AS n_edited_2mo,
  SUM(IF(n_additions_2mo > 0, 1, 0)) AS n_added_to_2mo
  FROM summarized_revisions
GROUP BY creation_date;
