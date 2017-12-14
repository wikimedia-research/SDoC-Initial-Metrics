# spark2R --master yarn --executor-memory 2G --executor-cores 1 --driver-memory 4G

# 43631973 files in total
# Files may have "needing category" and other categories at the same time

####
# All categories counts, excluding 'needing_category' categories
####
query <- "
SELECT img_media_type, files.cat_type, n_categories, COUNT(*) AS n_files
FROM chelsyx.mediawiki_image LEFT JOIN (

-- count n_categories for each file
SELECT mediawiki_page.page_title, 
IF(is_hiddencat = 'hiddencat', 'hiddencat', 'othercat') AS cat_type, 
COUNT(*) AS n_categories
FROM wmf_raw.mediawiki_page INNER JOIN chelsyx.mediawiki_categorylinks ON mediawiki_page.page_id=mediawiki_categorylinks.cl_from 
LEFT JOIN (

-- hidden cat name (unique)
SELECT page_title, pp_propname AS is_hiddencat
FROM  wmf_raw.mediawiki_page INNER JOIN chelsyx.mediawiki_page_props ON mediawiki_page_props.pp_page=mediawiki_page.page_id
WHERE pp_propname = 'hiddencat'
AND page_namespace = 14
AND snapshot = '2017-11'
AND mediawiki_page.wiki_db = 'commonswiki'
AND mediawiki_page_props.wiki_db = 'commonswiki'

) AS hidden_cat ON mediawiki_categorylinks.cl_to = hidden_cat.page_title   
WHERE cl_type = 'file'
AND INSTR(LOWER(cl_to), 'needing_categor') <= 0 -- exclude need cat/need cat review
AND page_namespace = 6
AND snapshot = '2017-11'
AND mediawiki_page.wiki_db = 'commonswiki'
AND mediawiki_categorylinks.wiki_db = 'commonswiki'
GROUP BY mediawiki_page.page_title, IF(is_hiddencat = 'hiddencat', 'hiddencat', 'othercat')

) AS files ON mediawiki_image.img_name = files.page_title
WHERE mediawiki_image.wiki_db = 'commonswiki'
GROUP BY img_media_type, files.cat_type, n_categories
"

category_counts <- collect(sql(query))
save(category_counts, file="data/sdoc/category_counts.RData")

system("scp chelsyx@stat5:~/data/sdoc/category_counts.RData data/")
load("data/category_counts.RData")


####
# Categories counts, excluding hidden categories and 'needing_category' categories
####
query <- "
SELECT img_media_type, n_categories, COUNT(*) AS n_files
FROM chelsyx.mediawiki_image LEFT JOIN (

-- count n_categories for each file, excluding hidden category and 'needing_category' category
SELECT mediawiki_page.page_title, 
COUNT(*) AS n_categories
FROM wmf_raw.mediawiki_page INNER JOIN chelsyx.mediawiki_categorylinks ON mediawiki_page.page_id=mediawiki_categorylinks.cl_from 
LEFT JOIN (

-- hidden cat name (unique)
SELECT page_title, pp_propname AS is_hiddencat
FROM  wmf_raw.mediawiki_page INNER JOIN chelsyx.mediawiki_page_props ON mediawiki_page_props.pp_page=mediawiki_page.page_id
WHERE pp_propname = 'hiddencat'
AND page_namespace = 14
AND snapshot = '2017-11'
AND mediawiki_page.wiki_db = 'commonswiki'
AND mediawiki_page_props.wiki_db = 'commonswiki'

) AS hidden_cat ON mediawiki_categorylinks.cl_to = hidden_cat.page_title   
WHERE cl_type = 'file'
AND INSTR(LOWER(cl_to), 'needing_categor') <= 0 -- exclude need cat/need cat review
AND page_namespace = 6
AND is_hiddencat IS NULL
AND snapshot = '2017-11'
AND mediawiki_page.wiki_db = 'commonswiki'
AND mediawiki_categorylinks.wiki_db = 'commonswiki'
GROUP BY mediawiki_page.page_title

) AS files ON mediawiki_image.img_name = files.page_title
WHERE mediawiki_image.wiki_db = 'commonswiki'
GROUP BY img_media_type, n_categories
"

category_no_hidden <- collect(sql(query))
save(category_no_hidden, file="data/sdoc/category_no_hidden.RData")

system("scp chelsyx@stat5:~/data/sdoc/category_no_hidden.RData data/")
load("data/category_no_hidden.RData")

