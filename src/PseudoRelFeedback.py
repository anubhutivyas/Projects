import BM25WithRelevance
import os
from QueryParser import Query_Parser
from context import Context
from BM25WithRelevance import BM25WithRelevance
from file_path import File_path

class PseudoRelFeedback:

    def __init__(self):
        self.modified_query = {}
        self.stop_words = []

    def getTopDocs(self,doc_scores,query_list,parsed_file_path,stop_words_path):
        self.getStopWords(stop_words_path)
        self.modified_query = query_list
        for query in query_list:
            #contains top 10 docs for this query
            top_docs = []
            # contains all terms of top 10 docs for this query
            terms = []
            i = 1
            #assumes docs are sorted according to the scores, takes top 10
            for doc in doc_scores[query]:
                if (i > 10):
                    break
                else:
                    top_docs.append(doc[0])
                    i += 1
            for html_file in os.listdir(parsed_file_path):
                if html_file in top_docs:
                    file = open(parsed_file_path+"/"+html_file, "r")
                    text = file.read()
                    words = text.split(" ")
                    terms.extend([word for word in words if word not in self.stop_words])
                    #Do if you want to remove numbers or else they will be most frequent
                    terms = [x for x in terms if not (x.isdigit() or x[0] == '-' and x[1:].isdigit())]
            #Get freq terms for this query, send term list and query_id
            self.getFreqWords(terms,query)
        return self.modified_query
        

    def getStopWords(self,stop_words_path):
        s_file = open(stop_words_path)
        self.stop_words = s_file.read().split("\n")

    def getFreqWords(self,terms,query):
        word_count = {}
        for term in terms:
            if term not in word_count.keys():
                word_count[term] = 1
            else:
                word_count[term] += 1
        top_terms = sorted(word_count, key=word_count.get, reverse=True)[:10]

        self.modified_query[query] += " " + " ".join(top_terms)
        

    def PRmain(self,parsed_foldername,index_file_path,parsed_query,relevance_file_path,stop_words_path,output_folder_path):

        f = open(parsed_query,"r")
        query = dict()
        for lines in f:
            lines = lines.split(":")
            query[lines[0]] = lines[1].strip()
        c = Context()
        index = c.read_inverted_index(index_file_path)
        DL = c.calculate_document_length(parsed_foldername)
        AvDL = c.calculate_avg_doc_length(parsed_foldername)
        bm = BM25WithRelevance("Bm25PRF_Round1")
        bm1 = BM25WithRelevance("BM25PseudoRelevanceFeedback")
        K = bm.calculate_K(parsed_foldername,AvDL,DL)

        doc_scores = bm.calculate_bm25_scores(query,index,parsed_foldername,K,relevance_file_path)
        #bm.retrieve_bm25_scores(query,parsed_foldername,AvDL,DL,index, relevance_file_path, output_folder_path)

        expanded_query = self.getTopDocs(doc_scores,query,parsed_foldername,stop_words_path)

        #sortedScores = bm1.calculate_bm25_scores(expanded_query,index,parsed_foldername,K,relevance_file_path)
        bm1.retrieve_bm25_scores(expanded_query, parsed_foldername, AvDL, DL, index, relevance_file_path,
                                output_folder_path)

