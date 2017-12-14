# copy password file
# hdfs dfs -cp /user/goransm/mysql-analytics-research-client-pw.txt /user/chelsyx/mysql-analytics-research-client-pw.txt

# on stat1004, try to see if I can connect
# sqoop list-tables  --password-file /user/chelsyx/mysql-analytics-research-client-pw.txt --username research --connect jdbc:mysql://analytics-store.eqiad.wmnet/commonswiki
# (Not on stat1005, see https://phabricator.wikimedia.org/T171258#3576267)

# Modified from https://phabricator.wikimedia.org/diffusion/AWCM/browse/master/WDCM_Sqoop_Clients.R

####
# Image: img_media_type, img_name
####

# Drop mediawiki_image
hiveCommand <- '"USE chelsyx; DROP TABLE IF EXISTS mediawiki_image;"'
hiveCommand <- paste("beeline -e ", hiveCommand, sep = "")
system(command = hiveCommand, wait = TRUE)

# Sqoop command
sqoopCommand <- paste(
  'sqoop import --connect jdbc:mysql://analytics-store.eqiad.wmnet/commonswiki', 
  '--password-file /user/chelsyx/mysql-analytics-research-client-pw.txt --username research -m 1',
  '--query "select convert(img_name using utf8) img_name, convert(img_media_type using utf8) img_media_type from image where \\$CONDITIONS" --split-by img_name --as-avrodatafile --target-dir /user/chelsyx/mediawiki_sqoop/mediawiki_image/wiki_db=commonswiki',
  '--delete-target-dir'
  )
# No int column as split column, so -m 1; see https://community.hortonworks.com/questions/26961/sqoop-split-by-on-a-string-varchar-column.html
system(command = sqoopCommand, wait = TRUE)

# Create Hive table
hiveCommand <- "\"USE chelsyx; CREATE EXTERNAL TABLE \\\`chelsyx.mediawiki_image\\\`(
                  \\\`img_name\\\`           string      COMMENT '',
                  \\\`img_media_type\\\`     string      COMMENT ''
                )
                COMMENT
                  ''
                PARTITIONED BY (
                  \\\`wiki_db\\\` string COMMENT 'The wiki_db project')
                ROW FORMAT SERDE
                  'org.apache.hadoop.hive.serde2.avro.AvroSerDe'
                STORED AS INPUTFORMAT
                  'org.apache.hadoop.hive.ql.io.avro.AvroContainerInputFormat'
                OUTPUTFORMAT
                  'org.apache.hadoop.hive.ql.io.avro.AvroContainerOutputFormat'
                LOCATION
                  'hdfs://analytics-hadoop/user/chelsyx/mediawiki_sqoop/mediawiki_image';\""
hiveCommand <- paste("beeline -e ", hiveCommand, sep = "")
system(command = hiveCommand, wait = TRUE)

# - repair partitions:
system(command = 'beeline -e "USE chelsyx; SET hive.mapred.mode = nonstrict; MSCK REPAIR TABLE mediawiki_image;"', wait = TRUE)


####
# Categorylinks: cl_from, cl_to, cl_type
####

# Drop mediawiki_categorylinks
hiveCommand <- '"USE chelsyx; DROP TABLE IF EXISTS mediawiki_categorylinks;"'
hiveCommand <- paste("beeline -e ", hiveCommand, sep = "")
system(command = hiveCommand, wait = TRUE)

# Sqoop command
sqoopCommand <- paste(
  'sqoop import --connect jdbc:mysql://analytics-store.eqiad.wmnet/commonswiki', 
  '--password-file /user/chelsyx/mysql-analytics-research-client-pw.txt --username research -m 4',
  '--query "select cl_from, convert(cl_to using utf8) cl_to, convert(cl_type using utf8) cl_type from categorylinks where \\$CONDITIONS" --split-by cl_from --as-avrodatafile --target-dir /user/chelsyx/mediawiki_sqoop/mediawiki_categorylinks/wiki_db=commonswiki',
  '--delete-target-dir'
  )
system(command = sqoopCommand, wait = TRUE)

# Create Hive table
hiveCommand <- "\"USE chelsyx; CREATE EXTERNAL TABLE \\\`chelsyx.mediawiki_categorylinks\\\`(
                  \\\`cl_from\\\`     bigint      COMMENT '',
                  \\\`cl_to\\\`       string      COMMENT '',
                  \\\`cl_type\\\`     string      COMMENT ''
                )
                COMMENT
                  ''
                PARTITIONED BY (
                  \\\`wiki_db\\\` string COMMENT 'The wiki_db project')
                ROW FORMAT SERDE
                  'org.apache.hadoop.hive.serde2.avro.AvroSerDe'
                STORED AS INPUTFORMAT
                  'org.apache.hadoop.hive.ql.io.avro.AvroContainerInputFormat'
                OUTPUTFORMAT
                  'org.apache.hadoop.hive.ql.io.avro.AvroContainerOutputFormat'
                LOCATION
                  'hdfs://analytics-hadoop/user/chelsyx/mediawiki_sqoop/mediawiki_categorylinks';\""
hiveCommand <- paste("beeline -e ", hiveCommand, sep = "")
system(command = hiveCommand, wait = TRUE)

# - repair partitions:
system(command = 'beeline -e "USE chelsyx; SET hive.mapred.mode = nonstrict; MSCK REPAIR TABLE mediawiki_categorylinks;"', wait = TRUE)

####
# Page_props: pp_propname, pp_page
####

# Drop mediawiki_page_props
hiveCommand <- '"USE chelsyx; DROP TABLE IF EXISTS mediawiki_page_props;"'
hiveCommand <- paste("beeline -e ", hiveCommand, sep = "")
system(command = hiveCommand, wait = TRUE)

# Sqoop command
sqoopCommand <- paste(
  'sqoop import --connect jdbc:mysql://analytics-store.eqiad.wmnet/commonswiki', 
  '--password-file /user/chelsyx/mysql-analytics-research-client-pw.txt --username research -m 4',
  '--query "select pp_page, convert(pp_propname using utf8) pp_propname from page_props where \\$CONDITIONS" --split-by pp_page --as-avrodatafile --target-dir /user/chelsyx/mediawiki_sqoop/mediawiki_page_props/wiki_db=commonswiki',
  '--delete-target-dir'
  )
system(command = sqoopCommand, wait = TRUE)

# Create Hive table
hiveCommand <- "\"USE chelsyx; CREATE EXTERNAL TABLE \\\`chelsyx.mediawiki_page_props\\\`(
                  \\\`pp_page\\\`         bigint      COMMENT '',
                  \\\`pp_propname\\\`     string      COMMENT ''
                )
                COMMENT
                  ''
                PARTITIONED BY (
                  \\\`wiki_db\\\` string COMMENT 'The wiki_db project')
                ROW FORMAT SERDE
                  'org.apache.hadoop.hive.serde2.avro.AvroSerDe'
                STORED AS INPUTFORMAT
                  'org.apache.hadoop.hive.ql.io.avro.AvroContainerInputFormat'
                OUTPUTFORMAT
                  'org.apache.hadoop.hive.ql.io.avro.AvroContainerOutputFormat'
                LOCATION
                  'hdfs://analytics-hadoop/user/chelsyx/mediawiki_sqoop/mediawiki_page_props';\""
hiveCommand <- paste("beeline -e ", hiveCommand, sep = "")
system(command = hiveCommand, wait = TRUE)

# - repair partitions:
system(command = 'beeline -e "USE chelsyx; SET hive.mapred.mode = nonstrict; MSCK REPAIR TABLE mediawiki_page_props;"', wait = TRUE)
