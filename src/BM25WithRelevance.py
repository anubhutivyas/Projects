import os
import math
import ast
from collections import Counter
import pprint

class BM25WithRelevance:
    
    def __init__(self,system_name):
        self.N = 0
        self.K = {}
        self.docLength = 0
        self.avgDocLength = 0
        self.k1 = 1.2
        self.b = 0.75
        self.k2 = 100
        self.RelInfo = {}
        self.system_name = system_name


    # calculate K for every document and store it ia dictionary
    # GIVEN : foldername - contains the folder path of the parsed
    #         avgDl      - Integer value that stores the average length of the corpus
    #         DL         - DL is a dictionary that contains the token count for every file
    def calculate_K(self,foldername,avgDL,DL):
        for file in os.listdir(foldername):
            if (file != ".DS_Store"):
                DocL = DL[file]
                K_val = self.k1*((1-self.b)+ self.b*(DocL/avgDL))
                self.K[file] = K_val
        return self.K


    # read relevance information from the file
    # GIVEN : path - the absolute path of the relevance information
    # RETURNS : RelInfo dictionary that stores the relevance information for every query
    #           queryId = [docIds]
    def get_relevance_info(self,path):
        with open(path) as f:
            for line in f:
                line = line.split()
                q_id = line[0]
                d_id = line[2]
                #print(line[2])
                if q_id not in self.RelInfo.keys():
                    self.RelInfo[q_id] = [d_id]
                else:
                    self.RelInfo[q_id].append(d_id)
    
    # Performs the BM25 ranking calculation
    # considers the relevance information from 
    # performs term at a time evaluation
    # GIVEN : queryList - contains the queries read from the file
    #         index - A dictionary containing the inverted Index
    #         foldername - contains the path of the parsed corpus
    #         K - a dictionary containing the K value for every document in the corpus
    #         relFilePath - the absolute path of the file containing relevance information

    def calculate_bm25_scores(self, queryList, index, foldername, K, relFilePath):
        scores = {}
        self.get_relevance_info(relFilePath)
        for queryId in queryList.keys():
            query = queryList[queryId]
            query = query.strip()
            # calculate the value of N -> number of documents in the corpus
            self.N = len(os.listdir(foldername))
            # split the query at space
            terms = query.split()
            # initialize a counter to store the frequency of the query terms in the given query
            qf = Counter(terms)
            R = 0
            if queryId in self.RelInfo.keys():
                # get the relevance document list for the given query by query ID
                RelDocList = self.RelInfo[queryId]
                R = len(RelDocList)
            # get the value of the ids only from the doument names in order to compare while finding ri
            RelDocIdList = []
            for docs in RelDocList:
                docs = docs.replace(".txt","")
                docs = int(docs[5:])
                RelDocIdList.append(docs)
            for term in terms:
                if term in index.keys():    
                    # fetch the inverted list for the given terms
                    inv_list = index[term]
                    listOfDocumentids = []
                    listOfDocuments = []
                    # for every entry in the inverted list, get the document ids
                    for postings in inv_list:
                        id = postings[0].replace(".txt", "")
                        listOfDocuments.append(id)
                        listOfDocumentids.append(int(id[5:]))
                    ri = 0
                    if (R > 0):
                        # the value of ri for this particular term
                        ri = len(set(listOfDocumentids).intersection(set(RelDocIdList)))
                    ni = len(inv_list)
                    eq1 = math.log(((ri+0.5)/(R-ri+0.5))/((ni-ri+0.5)/(self.N-ni-R+ri+0.5)))
                    eq3 = ((self.k2 + 1) * qf[term])/ (self.k2+qf[term])

                    # for every document in the inverted list of the term
                    for entries in inv_list:
                        docId = entries[0]
                        tf = entries[1]

                        eq2 = ((self.k1 +1)*tf) / (K[docId]+tf)
                        # score stores the final BM25 score
                        score = eq1*eq2*eq3

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
            sortedScores = {}
            # sort the documents based on the score
            for k in scores:
                sortedScores[k] = sorted(scores[k], key=lambda m: m[1], reverse=True)    
        return sortedScores

    def retrieve_bm25_scores(self,queryList,parsed_foldername,avgDL,DL,index, relFilePath, output_folder_path):
        K_dict = self.calculate_K(parsed_foldername,avgDL,DL)
        sortedScores = self.calculate_bm25_scores(queryList, index, parsed_foldername, K_dict, relFilePath)
        #sortedScores = {}
        # sort the documents based on the score
        #for k in s:
        #    sortedScores[k] = sorted(s[k], key=lambda m: m[1], reverse=True)
        #pp = pprint.PrettyPrinter(indent=4)
        #pp.pprint(sortedScores)
        final_output = []
        # print the documents in the file
        for q in sortedScores:
            queryId = queryList[q]
            rank = 1
            for docs in sortedScores[q]:
                if rank<=100:
                    docId = docs[0]
                    score = docs[1]
                    rank_string = str(q) + " Q0 "+ str(docId.replace(".txt",'')) +" "+str(rank) + " "+ str(score)+ " "+ self.system_name
                    final_output.append(rank_string)
                    rank +=1
        output_file_path = output_folder_path + "/" + self.system_name + ".txt"
        f = open(output_file_path,"w")
        for query_stat in final_output:
            print_statement = query_stat + "\n"
            f.write(str(query_stat)+"\n")