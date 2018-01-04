
from bs4 import BeautifulSoup, SoupStrainer
from urllib.request import urlopen
import ssl
import re
import string
import os

class Parser:
    global set_lower
    global punc

    # function to remove punctuations from strings and preserve in digits
    def remove_punctuation(self,list_strings):
        # regular expression to remove punctuations from string but preserve it in digits
        pattern = re.compile(r'((?<!\d)([!%\"#$&\'()*+,.:;<=>\/?@[\]^_`{|}~]+))|([,!@:()\\;.])(?![0-9])|([^\x00-\x7F]+)')
        pattern1 = re.compile(r'([\t\n]+)')
        final_text = []
        print("This si the input to the punctuation method")
        print(list_strings)
        # removes punctuation from the entire text
        for i in range(0,len(list_strings)):
            text = list_strings[i]
            print(text)
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
                print(file)
                parsed_file_path = dest_folder_path + "/" + file + ".txt"

                #get the text from the soup
                content = soup.get_text()
                print("this is the content")
                print(content.strip())

                # if set_lower is set, convert it to lower case
                if set_lower == True:
                    content = content.lower()
                text.append(content)

                # if punc is set, remove punctuations from the text
                if punc == True:
                    text = self.remove_punctuation(text)
                print("this is after punctuation removal")
                print(text)

                # write to the destination file
                fhand = open (parsed_file_path,"w")
                for t in text:
                    fhand.write(str(t).strip()+ " ")
                text.clear()

                file_names_final = "list_of_final_files.txt"
    

def main():
    # lower case and remove punctuations set to true by default
    lower_case = True
    remove_punc = True
    source_folder = input("Enter the path of the corpus folder \n")
    destination_folder = input("Enter the path of the destination folder i.e where to store the parsed docs\n")
    lower_case = input("Enter 'True' if you want to change to lowercase\n")

    if(lower_case.lower() != "true"):
        lower_case = False
    else:
        lower_case = True
    remove_punc = input("Enter 'True' if you want to remove punctuation\n")
    if(remove_punc.lower() == "true"):
        remove_punc = True
    else:
        remove_punc = False
    p = Parser()
    # calls the function to parse files
    p.parse_files(source_folder,destination_folder, lower_case , remove_punc)



main()
