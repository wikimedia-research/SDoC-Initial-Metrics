# mkdir python_virtualenv
# virtualenv -p python3 python_virtualenv/parse_wikitext
# source python_virtualenv/parse_wikitext/bin/activate
# deactivate

# pip install mwxml mysqltsv mwparserfromhell

import sys
import mwxml
import mysqltsv
import mwparserfromhell as mwp
from langdetect import detect
import glob
import urllib.request
from bs4 import BeautifulSoup
from iso639 import languages as iso_table

dump_files = glob.glob("/mnt/data/xmldatadumps/public/commonswiki/20171120/commonswiki-20171120-pages-articles*.xml-*.bz2")

# Get commons language code
langPage = urllib.request.urlopen("https://commons.wikimedia.org/wiki/Commons:Language_templates/table")
soup = BeautifulSoup(langPage, "html.parser")
langPage_table = soup.find("table", { "class" : "wikitable" })
rows = langPage_table.find_all('tr')
commons_lang_code = []
for tr in rows[1:]:
    lang_col = tr.find_all('td')[1]
    lang_text = lang_col.find('a').text
    commons_lang_code.append(lang_text)


infobox_list = ["Information", "Artwork", "Photograph", "Art photo", "Book", "Map", "Musical work", "Information2", "COAInformation", "Bus-Information", "Infobox aircraft image", "Spoken article", "Specimen", "NARA-image-full", "milim", "Fotothek-Description", "AFRE", "BLW2010", "Cepolina", "Flickr", "Image from the Florida Photographic Collection", "Indafotó", "NASA Photojournal", "ScottForesman", "Wikicon", "NLW collection", "NMW collection", "Nypl", "WPQC", "Object photo", "Google Art Project", "BHL", "Object photo"]
# See: https://commons.wikimedia.org/wiki/Commons:Infobox_templates
# https://commons.wikimedia.org/wiki/Category:Infobox_templates:_based_on_Information_template
# https://commons.wikimedia.org/wiki/Category:Data_ingestion_layout_templates
# can't include them all...
description_fields = ["original caption", "description", "title", "subtitle", "series title", "object type", "depicted people", "depicted place", "blazon of", "blazon"] 
# see https://commons.wikimedia.org/wiki/Commons:Infobox_templates

def first_lower(s):
   if len(s) == 0:
      return s
   else:
      return s[0].lower() + s[1:]
      
def first_upper(s):
   if len(s) == 0:
      return s
   else:
      return s[0].upper() + s[1:]

def process_language(lang_code):
  if len(lang_code) > 1 and len(lang_code) < 11 and first_lower(lang_code) not in ["doo", "age"]:
    simp_code = first_lower(lang_code.split("-")[0]).strip()
    try:
      lang_name = iso_table.get(part1=simp_code).name
    except:
      try:
        lang_name = iso_table.get(part2b=simp_code).name
      except:
        try:
          lang_name = iso_table.get(part2t=simp_code).name
        except:
          try:
            lang_name = iso_table.get(part3=simp_code).name
          except:
            try:
              lang_name = iso_table.get(part5=simp_code).name
            except:
              try:
                lang_name = iso_table.get(name=first_upper(simp_code)).name
              except:
                try:
                  if simp_code in commons_lang_code:
                    lang_name = simp_code
                  else:
                    raise ValueError
                except:
                  lang_name = None
  else:
    lang_name = None
  return lang_name   
      

def process_dump(dump, path):
  number_of_files = 0
  for page in dump:
    if page.namespace == 6 and page.redirect == None:
      number_of_files +=1     
        
      for revision in page:
        try:
            wikicode = mwp.parse(revision.text or "")
            all_templates = wikicode.filter_templates(recursive=True)
        except Exception as e:
            sys.stderr.write("Failed to parse text: " + str(e) + "\n")
        
        wikitext_length = len(revision.text.strip())
        has_infobox = False
        has_description_field = False
        languages = []
        detected_languages = []
        
        for template in all_templates:
          if template.name.matches(infobox_list):
            has_infobox = True
          
          for param in template.params:
            if param.name.lower().strip() in description_fields:
              has_infobox = True
              if template.has(param.name, ignore_empty=True):
                has_description_field = True
                try:
                  detected_languages.append(process_language(detect(str(param.value))))
                except:
                  pass
                    
          if template.name.matches(["LangSwitch", "mld", "mul", "Multilingual description", "Translation table"]):
            for lang in template.params:
              lang_name = process_language(lang.name)
              if lang_name is not None:
                languages.append(lang_name)
          elif process_language(template.name) is not None:
            languages.append(process_language(template.name))
          else:
            pass
                  
        # detect languages for text that are outside of template  
        try:
          detected_languages.append(process_language(detect(wikicode.strip_code().strip())))
        except:
          pass
                
        languages = list(set(languages))
        detected_languages = list(set(detected_languages))
          
        yield page.id, wikitext_length, has_infobox, has_description_field, str(languages), str(detected_languages)
  
  print("total files: " + str(number_of_files))
             
                
output = mysqltsv.Writer(open("data/sdoc/commonswiki_20171120_files_description.tsv", "w"), headers=["page_id", "wikitext_length", "has_infobox", "has_description_field", "languages", "detected_languages"])

for page_id, wikitext_length, has_infobox, has_description_field, languages, detected_languages in mwxml.map(process_dump, dump_files):
  output.write([page_id, wikitext_length, has_infobox, has_description_field, languages, detected_languages])



# compress the tsv file
# tar -czvf commonswiki_20171120_files_description.tar.gz commonswiki_20171120_files_description.tsv
                