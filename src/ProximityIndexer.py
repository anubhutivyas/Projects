import os
import json

class ProximityIndexer:

    def __init__(self):
        self.n_grams = 1
        self.index = {}

    def generate_inverted_index(self,parsed_file_path,index_path):
        for filename in os.listdir(parsed_file_path):
            if filename.endswith(".txt"):
                with open(parsed_file_path + "/" + filename, "r",encoding='utf-8') as f:
                    tokens = []
                    for line in f:
                        tokens = line.split(" ")

                    i = 1

                    for term in tokens:
                        if not term == "":
                            if term not in self.index.keys():
                                self.index[term] = [[filename, 1,[i]]]
                            else:
                                flag = 0
                                for e in self.index[term]:
                                    if(e[0] == filename):
                                        e[1] += 1
                                        e[2].append(i)
                                        flag += 1
                                if (flag == 0):
                                    self.index[term].append([filename,1,[i]])
                            i = i+1

        file = open(index_path, "w", encoding='utf-8')
        file.write(json.dumps(self.index))
        file.close()

