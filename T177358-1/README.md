# Wikimedia Commons: Language of Files

We parsed the wikitext of all files in [Commons xml data dumps of November 20, 2017](https://dumps.wikimedia.org/commonswiki/20171120/), and extract the language templates in them (e.g. [{{en}}](https://commons.wikimedia.org/wiki/Template:En), [{{LangSwitch}}](https://commons.wikimedia.org/wiki/Template:LangSwitch)). Out of the total 43,268,565 files, 14,848,551 (34.32%) files don't have any language templates, 23,780,247 (54.96%) files use only 1 language.

![Files by number of language templates](figures/files_by_n_languages.png)

40.1% of all files have English templates, 9.38% of files use German, and 6.2% of files have description in languages which are not in the top 20. 

![Files by top 20 language templates](figures/top20_languages_nfiles.png)

For those files without language template, we use the [langdetect package](https://pypi.python.org/pypi/langdetect) to detect their languages. We cannot detect any language in 556,684 files (1.29% of all 43,268,565 files). We detect 1 language for 7,577,789 (17.51%) files.

![Files by number of detected languages](figures/files_by_n_detected_languages.png)

We detect English in 30.25% of all 43,268,565 files, detect German in 3.93% of files.

![Files by top 20 detected languages](figures/top20_detected_languages_nfiles.png)
