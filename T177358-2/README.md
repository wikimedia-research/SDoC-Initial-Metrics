# Wikimedia Commons: Language of Search

A look at which languages users search Wikimedia Commons in.

## Setup

- Google's [Compact Language Detector](https://github.com/google/cld3) (CLDv3)
    - Neural network model for language identification
    - R bindings via [cld2](https://github.com/ropensci/cld2)
    - R bindings via [cld3](https://github.com/ropensci/cld3) (required `libprotobuf-dev` & `protobuf-compiler`)
- [Hunspell](http://hunspell.github.io/) for naive detection by comparing against dictionaries
    - R bindings via [hunspell](https://github.com/ropensci/hunspell)
    - [Dictionaries](https://github.com/wooorm/dictionaries)
    - Implemented but not included in the final determination due to abysmal error rate
- [TextCat](https://www.mediawiki.org/wiki/TextCat)
    - [Perl port](https://github.com/Trey314159/TextCat)
    - Used language models trained on short text and those trained on longer text

## Results

**Caution!** It should be noted that these numbers are to be taken with a _HUGE_ [pile of salt](https://en.wikipedia.org/wiki/Grain_of_salt). Language detection on short text (such as search queries) is _extremely difficult_ to get correct because of how few characters the algorithms have to make a prediction from. (Unlike, say, detecting language of an essay or a book.) This is especially problematic when the search query was a proper noun. For example, only CLDv3 returned a language prediction for "wii u" (a Nintendo game console) but that prediction was "German", while the other methods such as TextCat and CLDv2 did not return anything. Or you have cases like "solar" being detected as Azerbaijani while in the same session none of the algorithms detected any language for "solar systetm".

|language                      |approx. %|
|:-----------------------------|:--------|
|English                       |38.4243% |
|German                        |5.0856%  |
|French                        |3.9716%  |
|Latin                         |3.3742%  |
|Italian                       |3.3097%  |
|Spanish; Castilian            |2.6316%  |
|Portuguese                    |2.0665%  |
|Norwegian                     |1.7598%  |
|Dutch; Flemish                |1.7113%  |
|Danish                        |1.6629%  |
|Afrikaans                     |1.5983%  |
|Chinese                       |1.3400%  |
|Catalan; Valencian            |1.3077%  |
|Japanese                      |1.2916%  |
|Polish                        |1.1786%  |
|Luxembourgish; Letzeburgesch  |1.0494%  |
|Serbian                       |1.0494%  |
|Welsh                         |1.0171%  |
|Galician                      |0.8557%  |
|Estonian                      |0.8395%  |
|Hindi                         |0.8395%  |
|Finnish                       |0.8234%  |
|Russian                       |0.7588%  |
|Czech                         |0.7427%  |
|Indonesian                    |0.7427%  |
|Swedish                       |0.7265%  |
|Western Frisian               |0.7265%  |
|Bulgarian                     |0.6942%  |
|Hungarian                     |0.6619%  |
|Ukrainian                     |0.6619%  |
|Malagasy                      |0.6458%  |
|Javanese                      |0.6296%  |
|Greek, Modern (1453-)         |0.5974%  |
|Haitian; Haitian Creole       |0.5974%  |
|Romanian; Moldavian; Moldovan |0.5328%  |
|Malay                         |0.5166%  |
|Basque                        |0.5005%  |
|Bosnian                       |0.5005%  |
|Slovenian                     |0.5005%  |
|Corsican                      |0.4682%  |
|Esperanto                     |0.4682%  |
|Sundanese                     |0.4521%  |
|Turkish                       |0.4359%  |
|Hausa                         |0.4198%  |
|Lithuanian                    |0.3713%  |
|Shona                         |0.3713%  |
|Arabic                        |0.3552%  |
|Igbo                          |0.3552%  |
|Gaelic; Scottish Gaelic       |0.3390%  |
|Irish                         |0.3390%  |
|Latvian                       |0.3390%  |
|Azerbaijani                   |0.3229%  |
|Belarusian                    |0.3229%  |
|Chichewa; Chewa; Nyanja       |0.3229%  |
|Kirghiz; Kyrgyz               |0.3229%  |
|Korean                        |0.3229%  |
|Somali                        |0.3229%  |
|Maltese                       |0.3067%  |
|Croatian                      |0.2583%  |
|Sotho, Southern               |0.2422%  |
|Icelandic                     |0.2260%  |
|Persian                       |0.2260%  |
|Uzbek                         |0.2260%  |
|Swahili                       |0.1937%  |
|Xhosa                         |0.1937%  |
|Samoan                        |0.1776%  |
|Zulu                          |0.1614%  |
|Kurdish                       |0.1453%  |
|Yoruba                        |0.1453%  |
|Kazakh                        |0.1292%  |
|Macedonian                    |0.1130%  |
|Mongolian                     |0.1130%  |
|Slovak                        |0.1130%  |
|Maori                         |0.0969%  |
|Thai                          |0.0969%  |
|Vietnamese                    |0.0969%  |
|Albanian                      |0.0807%  |
|Breton                        |0.0807%  |
|Georgian                      |0.0807%  |
|Kinyarwanda                   |0.0807%  |
|Sindhi                        |0.0807%  |
|Tagalog                       |0.0484%  |
|Tajik                         |0.0484%  |
|Bengali                       |0.0323%  |
|Marathi                       |0.0323%  |
|Pushto; Pashto                |0.0323%  |
|Armenian                      |0.0161%  |
|Burmese                       |0.0161%  |
|Central Khmer                 |0.0161%  |
|Tamil                         |0.0161%  |
|Urdu                          |0.0161%  |
|Yiddish                       |0.0161%  |
