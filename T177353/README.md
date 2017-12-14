# Wikimedia Commons: "Unfindable" images metrics

## Lack of categorization

Excluding [hidden categories](https://commons.wikimedia.org/wiki/Commons:Categories#Categories_marked_with_"HIDDENCAT") and ['needing_category' categories](https://commons.wikimedia.org/wiki/Category:Media_needing_categories_requiring_human_attention), there are 1,629,592 (3.73%) files that don't belong to any category, 22,492,880 (51.55%) files belong to only 1 category as of December 12, 2017.

![Number of files by number of categories](nfile_by_categories.png)

|img_media_type |n_categories  |  n_files|proportion |
|:-------------:|:------------:|:-------:|:---------:|
|AUDIO          |0 category    |     2007|0.25%      |
|AUDIO          |1 category    |   404697|50.54%     |
|AUDIO          |2 categories  |   346496|43.27%     |
|AUDIO          |3 categories  |    15327|1.91%      |
|AUDIO          |4 categories  |     6667|0.83%      |
|AUDIO          |5+ categories |    25552|3.19%      |
|BITMAP         |0 category    |  1599973|3.89%      |
|BITMAP         |1 category    | 21292109|51.73%     |
|BITMAP         |2 categories  |  9944133|24.16%     |
|BITMAP         |3 categories  |  4379117|10.64%     |
|BITMAP         |4 categories  |  1886515|4.58%      |
|BITMAP         |5+ categories |  2057464|5%         |
|DRAWING        |0 category    |    11228|0.94%      |
|DRAWING        |1 category    |   485009|40.5%      |
|DRAWING        |2 categories  |   358924|29.97%     |
|DRAWING        |3 categories  |   149269|12.46%     |
|DRAWING        |4 categories  |   118525|9.9%       |
|DRAWING        |5+ categories |    74735|6.24%      |
|MULTIMEDIA     |1 category    |        2|50%        |
|MULTIMEDIA     |2 categories  |        1|25%        |
|MULTIMEDIA     |3 categories  |        1|25%        |
|OFFICE         |0 category    |     3869|1.06%      |
|OFFICE         |1 category    |   285574|78.54%     |
|OFFICE         |2 categories  |    38990|10.72%     |
|OFFICE         |3 categories  |    24767|6.81%      |
|OFFICE         |4 categories  |     5918|1.63%      |
|OFFICE         |5+ categories |     4475|1.23%      |
|VIDEO          |0 category    |    12515|11.31%     |
|VIDEO          |1 category    |    25489|23.04%     |
|VIDEO          |2 categories  |    19412|17.55%     |
|VIDEO          |3 categories  |    13702|12.39%     |
|VIDEO          |4 categories  |    10028|9.06%      |
|VIDEO          |5+ categories |    29483|26.65%     |

## Lack of description

We parsed the wikitext of all files in [Commons xml data dumps of November 20, 2017](https://dumps.wikimedia.org/commonswiki/20171120/). Out of the total 43,268,565 files, 41,796,560 (96.6%) files have a [infobox](https://dumps.wikimedia.org/commonswiki/20171120/), 41,309,028 (95.47%) have some contents in their description fields (description, title, depicted people, depicted place, etc). Analysis codebase: https://github.com/wikimedia-research/SDoC-Initial-Metrics/tree/master/T177358-1 .

Caveat:

There are a large number of infobox-like templates (e.g. [Infobox_templates:_based_on_Information_template](https://commons.wikimedia.org/wiki/Category:Infobox_templates:_based_on_Information_template), [Data_ingestion_layout_templates](https://commons.wikimedia.org/wiki/Category:Data_ingestion_layout_templates), templates only for one batch of uploads like [this](https://commons.wikimedia.org/wiki/Template:Ingestion-Berthel%C3%A9)) with description fields of various names (e.g. some use commons_description instead of description). This makes counting very difficult because we cannot enumerate all of these infobox names and description field names.
Some users create their own templates on top of other infobox templates for upload convenience. This makes the file description masked -- they cannot be search. For example, the wikitext of [File:Cyclopaedia, Chambers - Volume 1 - 0133.jpg](https://commons.wikimedia.org/wiki/File:Cyclopaedia,_Chambers_-_Volume_1_-_0133.jpg) is:
```
{{Cyclopaedia, Chambers page
 | volume = 1
 | prev = 0132
 | page = 0133
 | next = 0134
}}
```
A lot of the information we see on the web page is actually hidden in its template [Template:Cyclopaedia,_Chambers_page](https://commons.wikimedia.org/wiki/Template:Cyclopaedia,_Chambers_page). This makes it very hard to find this file through search, because search is done by matching the above shown wikitext of this file. We should encourage our users to clean up this kind of templates.

## ImageNote

There are 146,043 files with annotations ([ImageNote](https://commons.wikimedia.org/wiki/Template:ImageNote)) on December 14, 2017. Follow [this link](https://commons.wikimedia.org/w/index.php?search=insource%3A%2F%5C%7B%5C%7B%5B%5Ct+%5D%2A%5BIi%5Dmage%5BNn%5Dote%5B%5Ct+%5D%2A%5C%7C%2F&title=Special:Search&profile=advanced&fulltext=1&ns6=1&searchToken=60cczpm68lwa66h1rmsgltdze) for the most current count.
