import os

class StoppedCorpus:

    # GIVEN:
    # stop_corpus_path: path where sttoped documents are stored
    # parsed_corpus_path: path where parsed documents are stored
    # parsed_query_path: path of parsed query file(with file name)
    # stop_query_path: path where sttoped query file will be stored(without file name)
    # stop_file_path: path of list of stop words
    #
    # RETURNS: stores stopped corpus and stopped queries at given path

    def stop_corpus(self,stop_corpus_path,parsed_corpus_path,parsed_query_path,stop_query_path,stop_file_path):
        #list of stop words
        stop_words = self.getStopWords(stop_file_path)
        # for every parsed document creates a stopped version of it
        for html_file in os.listdir(parsed_corpus_path):
            file = open(parsed_corpus_path +"/" + html_file, "r")
            text = file.read()
            words = text.split(" ")
            terms = [word for word in words if word not in stop_words]
            file.close()
            file1 = open(stop_corpus_path + "/"+ html_file, "w")
            file1.write(" ".join(terms))
            file1.close()
        # stopped queries
        file = open(parsed_query_path,"r")
        queries = file.readlines()
        #queries = queries.split("\n")
        file.close()
        for query in queries:
            query1 = query.split(":")
            query = query1[1].split(" ")
            parsed_query = [word for word in query if word not in stop_words]
            file1 = open(stop_query_path,"a")
            file1.write(query1[0]+":"+" ".join(parsed_query))
            file1.write("\n")
        file1.close()

    # GIVEN: path of file of stop words list
    # RETURNS: list of stop words
    
    def getStopWords(self,stop_file_path):
        s_file = open(stop_file_path)
        stop_words = s_file.read().split("\n")
        return stop_words