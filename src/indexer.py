import os

class Indexer:
    def __init__(self):
        self.unigram_token = {}
        self.index_uni = {}
        
    # function to modify the index and increase the term frequency if the term is
    # present, if not, add the term in the index
    def add_to_index(self,index_list, term, doc_id):
        # if the term is not present, add it to the index and create an inverted list
        # and create an inverted list
        if term not in index_list.keys():
            index_list[term] = [[doc_id,1]]
        else:
            flag = True
            # increment the tf for the right document if term is already present
            for every_val in index_list.get(term):
                if every_val[0] == doc_id:
                    every_val[1]+=1
                    flag = False
            # if the term is present but inverted list doesn't  contain the doc_id
            # append docId to inverted list along with tf = 1
            if flag is True:
                index_list.get(term).append([doc_id,1])

    # takes a folderpath, creates a collective unigram index for every file in that
    # folder.
    def unigram_index(self,foldername):
        final = []
        # for every file in the given folder
        for file in os.listdir(foldername):
            # if the file isn't .DS_Store(file directly created on mac Os if using an IDE)
            if (file != ".DS_Store"):
                file_path = foldername + "/"+ file
                # open the file and read the content
                f = open(file_path, "r+")
                for lines in f:
                    words = lines.split(" ")
                    # the token count is the unique count of words in the file
                    unigram_token_count = len(set(words))
                    self.unigram_token[file] = unigram_token_count
                    for word in words:
                        word = word.strip()
                        if word != '':
                            final.append(word)
                            # for every unigram in the list, alter the index accordingly
                            self.add_to_index(self.index_uni, word, file)
            final.clear()
        return self.index_uni
    
    def create_unigram_index(self, foldername,index_file_name):
        # call the function to create the index and write it to a file
        uni_index = self.unigram_index(foldername)
        f = open(index_file_name, "w")
        for term in uni_index:
            f.write(str(term) + " :> " + (str(uni_index.get(term))) + "\n")
        f.close()

