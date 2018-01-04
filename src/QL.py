import pprint
import math
class QueryLikelihood:
    def __init__(self, system_name):
        self.lmbda = 0.35
        self.system_name = system_name

    def calculateQL(self,fq,dl,cq,C):
        return math.log((((1-self.lmbda)*fq/dl)/self.lmbda*cq/C)+1)
        
    def calculate_C(self, DL):
        sum = 0
        for doc in DL:
            sum += DL[doc]
        return sum;

    def calculate_QL_scores(self, DL, queryList,index):
        scores = {}
        sortedScores = {}
        # calculate the number of words in the entire collection
        C = self.calculate_C(DL)
        for queryId in queryList:
            inverted_list = {}
            doc_scores = {}
            query_string = queryList[queryId]
            terms = query_string.split(" ")
            for term in terms:
                if term in index.keys():
                    inv_list = index[term]
                    cq = 0
                    for docs in inv_list:
                        docId = docs[0]
                        cq += docs[1]
                    for docs in inv_list:
                        tf = docs[1]
                        d = DL[docs[0]]
                        score = self.calculateQL(tf,d,cq,C)
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

    def retrieve_QL_scores(self, DL, queryList,index,output_folder_path):
        #s = self.calculate_QL_scores(DL, queryList, index)
        # print the documents in the file
        s = self.calculate_QL(queryList,index, DL)
        final_output = []
        for q in s:
            queryId = q
            #queryId = queryList[q]
            rank = 1
            for docs in s[q]:
                if rank<=100:
                    docId = docs[0]
                    score = docs[1]
                    #print(queryId, " Q0 ", docId," ",rank , " ", score, " ", system_name)
                    rank_string = str(queryId) + " Q0 "+ str(docId) +" "+str(rank) + " "+ str(score)+ " "+ self.system_name
                    final_output.append(rank_string)
                    rank +=1
        output_file_path = output_folder_path + "/" + self.system_name + ".txt"
        f = open(output_file_path,"w")
        for query_stat in final_output:
            #print_statement = query_stat + "\n"
            f.write(str(query_stat)+"\n")


    def calculate_QL(self,query,index, DL):
        scores = {}
        sortedScores = {}
        C = self.calculate_C(DL)
        for queryId in query:
            query_string = query[queryId]
            terms = query_string.split()
            for term in terms:
                if term in index.keys():
                    inv_list = index[term]
                    cq = 0
                    for docs in inv_list:
                        cq += docs[1]
                    for each in inv_list:
                        docId = each[0]
                        tf = each[1]
                        dl = DL[docId]
                        score = math.log((((1-self.lmbda)*tf/dl)/self.lmbda*cq/C)+1)
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


