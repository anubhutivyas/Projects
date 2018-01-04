import os
from bs4 import BeautifulSoup
import re
import operator
import string
import time
from urllib.parse import urlparse
class Query_Parser:
    def parse_queries(self,queryfile_path,parsed_query):
        query_dict = {}

        f = open(queryfile_path, 'r')
        texts = f.read()

        soup = BeautifulSoup(texts, "html5lib")

        for docTag in soup.find_all('doc'):
            key = docTag.find('docno')
            key = key.get_text()
            key = re.sub(r'\s','',key)
            dno = docTag.find('docno')
            dno.extract()
            value = docTag.get_text()
            value = re.sub(r'((?<!\d)([!%\"#$&\'()*+,.:;<=>\/?@[\]^_`{|}~]+))|([,!@:()\\;.])(?![0-9])|([^\x00-\x7F]+)|([\t\n]+)', ' ', value)
            value = re.sub(r'^\s','',value)
            value = re.sub(r'--', ' ', value)
            pattern1 = re.compile(r'([\t\n\s]+)')
            value = re.sub(pattern1," ",value)
            #value = re.sub(r'\n', '',value)
            value = value.lower()
            #print(value)
            query_dict[key] = value.strip()

        f = open(parsed_query, 'w')
        sorted_dict = sorted(query_dict.items(), key=operator.itemgetter(0))
        for k in query_dict.keys():
            f.write(k+":"+query_dict[k].strip()+"\n")
        f.close()
