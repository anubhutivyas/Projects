import math
from context import Context

class ProximitySearch:

    def __init__(self):
        self.index = {}
        self.query = {}

    def getIndex(self,index_path):
        file = open(index_path)
        self.index = eval(file.read())
        file.close()
        # print(self.index)

    def getQueries(self,query_path):
        f = open(query_path, "r")
        for lines in f:
            if (lines != "" and lines != "\n"):
                lines = lines.split(":")
                self.query[lines[0]] = lines[1].strip()

    def calculate_score(self,tf1,tf2,n1,n2,N):
        first = tf1 * math.log(N / (n1 + 1))
        second = tf2*math.log(N/(n2+1))
        return (first+second)/2


    def searchDocs(self,index_path,query_path,DL,output_path,sys_name):
        N = len(DL)
        self.getIndex(index_path)
        self.getQueries(query_path)

        for query in self.query:
            doc_scores = {}

            query_string = self.query[query]
            query_string = query_string.split(" ")

            for i in range(0,len(query_string)-1):
                posting1 = []
                posting2 = []
                if (query_string[i] in self.index.keys()):
                    posting1 = self.index[query_string[i]]
                if (query_string[i+1] in self.index.keys()):
                    posting2 = self.index[query_string[i + 1]]

                if (len(posting1) > 0 and len(posting2) > 0):
                    for doc1 in posting1:
                        for doc2 in posting2:
                            if (doc1[0] == doc2[0]):
                                tf1 = doc1[1]
                                tf2 = doc2[1]
                                n1 = len(posting1)
                                n2 = len(posting2)
                                pos_p1 = doc1[2]
                                pos_p2 = doc2[2]
                                if (len(pos_p1) > 0 and len(pos_p2) > 0):
                                    for p2 in pos_p2:
                                        for p1 in pos_p1:
                                            if (p2 - p1 <= 3 and p2 - p1 > 0):
                                                if doc1[0] not in doc_scores.keys():
                                                    doc_scores[doc1[0]] = self.calculate_score(tf1,tf2,n1,n2,N)+(1 - ((p2 - p1)/10))
                                                else:
                                                    doc_scores[doc1[0]] += self.calculate_score(tf1,tf2,n1,n2,N)+(1 - ((p2 - p1)/10))
            top_docs = sorted(doc_scores, key=doc_scores.get, reverse=True)[:50]

            if(sys_name == "NoStopNoStemProximityTf-Idf"):
                f = open(output_path+"/NoStopNoStemResults.txt","a")
            elif (sys_name == "StoppedProximityTf-Idf"):
                f = open(output_path + "/StoppedResults.txt","a")

            i = 1
            for doc in top_docs:
                f.write(query + " Q0 " + doc + " " + str(i) + " " + str(doc_scores[doc]) + " " + sys_name)
                f.write("\n")
                i = i + 1
            f.close()







