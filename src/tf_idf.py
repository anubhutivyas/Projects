import math
import os
import pprint

class Tf_idf:
    def __init__(self, system_name):
        self.N =0
        self.top_docs = {}
        self.system_name = system_name
        
    # function to calculate the rank using tf idf
    # GIVEN : N - total number of docuemnts in the corpus
    #         n - nuber of documents the term occurs in
    #         tf - the term frequency of the given term

    def calculate_tfidf(self,tf,n,N):
        return tf*math.log(N/(n+1))
        
    
    # calculates the scores for the given queries in the queryList
    # GIVEN : DL - a dictionary containing the document length/ token counts for the 
    #              documents in the query
    #         queryList - The list of queries for which the results are generated
    #         index - contains the inverted index of the corpus
    def calculate_results_tdidf(self, DL, queryList, index):
        N = len(DL)
        for queryId in queryList.keys():
            inverted_list = {}
            doc_scores = {}
            query_string = queryList[queryId]
            for term in query_string.split(" "):
                if term in index.keys():
                    inverted_list[term] = index.get(term)
            for posting in inverted_list:
                n = len(inverted_list[posting])
                for doc in inverted_list[posting]:
                    if doc[0] not in doc_scores.keys():
                        doc_scores[doc[0]] = self.calculate_tfidf(doc[1],n,N)
                    else:
                        doc_scores[doc[0]] += self.calculate_tfidf(doc[1],n,N)
            self.top_docs[queryId] = sorted(doc_scores, key=doc_scores.get, reverse=True)[:100]
        return self.top_docs
    

    def calc_tfidf_score(self, DL, queryList, index):
        N = len(DL)
        scores = {} 
        sortedScores = {}       
        for queryId in queryList.keys():
            query = queryList[queryId]
            query = query.strip()
            # split the query at space
            terms = query.split()
            for term in terms:
                if term in index.keys():
                    inv_list = index.get(term)
                    n = len(inv_list)
                    for documents in inv_list:
                        docId = documents[0]
                        tf = documents[1]
                        score = self.calculate_tfidf(tf,n,N)
                        # update the score for the document for the given query term
                        if queryId not in scores.keys():
                            scores[queryId] = [[docId,score]]
                        else:
                            flag = True
                            for val in scores.get(queryId):
                                if val[0] == docId:
                                    val[1] += score
                                    flag = False
                            if flag:
                                scores.get(queryId).append([docId,score])
        for k in scores:
            sortedScores[k] = sorted(scores[k], key=lambda m: m[1], reverse=True)
        return sortedScores

    # prints the results of the queires in a file
    # GIVEN : DL - a dictionary containing the document length/ token counts for the 
    #              documents in the query
    #         queryList - The list of queries for which the results are generated
    #         index - contains the inverted index of the corpus
    def retrieve_tfidf_scores(self,DL, queryList, index,output_folder_path):
        s = self.calc_tfidf_score(DL, queryList, index)
        # print the documents in the file
        final_output = []
        for q in s:
            queryId = q
            rank = 1
            for docs in s[q]:
                if rank<=100:
                    docId = docs[0]
                    score = docs[1]
                    rank_string = str(queryId) + " Q0 "+ str(docId) +" "+str(rank) + " "+ str(score)+ " "+ self.system_name
                    final_output.append(rank_string)
                    rank +=1
        output_file_path = output_folder_path + "/" + self.system_name + ".txt"
        f = open(output_file_path,"w")
        for query_stat in final_output:
            f.write(str(query_stat)+"\n")