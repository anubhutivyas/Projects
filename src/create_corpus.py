import re
import os
from bs4 import BeautifulSoup, SoupStrainer

class Create_corpus:
    def __init__(self, folderpath,set_lower,remove_punc):
        self.folderpath = folderpath
        self.set_lower = set_lower
        self.remove_punc = remove_punc

    # function to remove punctuations from strings and preserve in digits
    def remove_punctuation(self,list_strings):
        # regular expression to remove punctuations from string but preserve it in digits
        pattern = re.compile(r'((?<!\d)([!%\"#$&\'()*+,.:;<=>\/?@[\]^_`{|}~]+))|([,!@:()\\;.])(?![0-9])|([^\x00-\x7F]+)')
        pattern1 = re.compile(r'([\t\n]+)')
        final_text = []
        # removes punctuation from the entire text
        for i in range(0,len(list_strings)):
            text = list_strings[i]
            text = re.sub(pattern, "" , text)
            text = re.sub(pattern1, " ",text)
            final_text.append(text)
        return final_text

    # source folder path => parses the file and stores it in the destination folder
    def parse_files(self,folderpath, dest_folder_path, set_lower , punc):
        text = []
        source_folder_path = folderpath

        #for every file in the given directory, do the parsing
        for file in os.listdir(source_folder_path):
            # if the file isn't DS store (added by mac os by default)
            if (file != ".DS_Store"):
                file_path = source_folder_path + "/"+ file
                fhand = open(file_path, "r+")
                content = fhand.read()

                # get all the <p> tags from the htm content from the file
                soup = BeautifulSoup(content,"html.parser", parse_only=SoupStrainer("pre"))
                fhand.close()

                # modify the parsed file name by adding the path to it
                file = file.replace(".html","")
                parsed_file_path = dest_folder_path + "/" + file + ".txt"

                #get the text from the soup
                content = soup.get_text()

                # if set_lower is set, convert it to lower case
                if set_lower == True:
                    content = content.lower()
                text.append(content)

                # if punc is set, remove punctuations from the text
                if punc == True:
                    text = self.remove_punctuation(text)

                # write to the destination file
                fhand = open (parsed_file_path,"w")
                for t in text:
                    fhand.write(str(t).strip()+ " ")
                text.clear()

