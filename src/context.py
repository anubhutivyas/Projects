import ast
import os
# This class contains functions to read the index from file, etc. 
class Context:
    def __init__(self):
        self.index = {}
        self.queries = {}
        self.document_length = {}
        self.avg_length = {}

    # read the inverted index from the file and store it in a dictionary
    # the inverted index file should be stored as key :> value
    def read_inverted_index(self,filename):
        f = open(filename,"r")
        for lines in f:
            key_val = lines.split(":>")
            key = key_val[0].strip()
            value = ast.literal_eval(key_val[1].strip())
            pos = lines.index(":")
            self.index[key]= value
            #print(index)
        return self.index

    # calculate the document lenth of the document and store it in a dictionary
    # the foldername that's passed to the function should contain the parsed documents
    def calculate_document_length(self, foldername):
        no_of_files = 0
        #docLength= {}
        for file in os.listdir(foldername):
            words = []
            if (file != ".DS_Store"):
                count = 0
                no_of_files +=1
                file_path = foldername + "/"+ file
                f2 = open(file_path, "r+")
                word_list = f2.read().split(' ')
                for word in word_list:
                    if word != '':
                        words.append(word)
                count = len(words)
                self.document_length[file]=count
        #print(document_length)
        return self.document_length

    # calculate the average document length of the parsed files
    def calculate_avg_doc_length(self,foldername):
        count = 0
        no_of_files = 0
        # for every file in the folder, calculate the length of the files
        for file in os.listdir(foldername):
            words = []
            if (file != ".DS_Store"):
                no_of_files +=1
                file_path = foldername + "/"+ file
                f2 = open(file_path, "r+")
                word_list = f2.read().split(' ')
                for word in word_list:
                    if word != '':
                        words.append(word)
                count = count + len(words)
        # calculate the average length
        self.avg_length = count / no_of_files
        #print(avg_length)
        return self.avg_length
