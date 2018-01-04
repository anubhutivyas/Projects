from collections import OrderedDict
import os

class Evaluation:

    # DATA DEFINITIONS:
    doc_dict = OrderedDict()       # dictionary containing the ranked list information
    RelInfo = OrderedDict()        # dictionary containing relevance information
    precision_dict = OrderedDict() # dictionary containing the precision values of all 100
                        # documents for every query
    recall_dict = OrderedDict()    # dictionary containing the recall values of all 100
                        # documents for every query
    map_dict = OrderedDict()       # dictionary containing the mean average precision
                        # of each query
    mrr_dict = OrderedDict()       # dictionary containing the mean reverse ranking
                        # of each query


    # get_ranklist(self,output_file)
    # GIVEN  : output_file which is the path of the file that contains
    #          the ranklist
    # EFFECT : this function reads the output_file and creates a
    #          dictionary doc_dict
    # WHERE  : output_file is the absolute path
    #          key of doc_dict is the query id
    #          value of doc_dict is another dictionary dict
    #          key of dict is the docID
    #          value of dict is its rank

    def get_ranklist(self, output_file):
        f = open(output_file, 'r')
        info = f.readlines()
        f.close()
        for line in info:
            words = line.split()
            d_dict = OrderedDict()
            key = words[0]
            doc_name = words[2].rstrip(".txt")
            d_dict[doc_name] = words[3]
            if key in self.doc_dict.keys():
                dict = self.doc_dict[key]
                dict.update(d_dict)
                self.doc_dict[key] = dict
            else:
                self.doc_dict[key] = d_dict


    # get_relevance_info(self, path)
    # GIVEN  : path which is the path of the file that contains
    #          the relevance information
    # EFFECT : creates a dictionary RelInfo
    # WHERE  : path is the absolute path
    #          key of RelInfo is the query id
    #          value is a list of docIds

    def get_relevance_info(self, path):
        with open(path) as f:
            for line in f:
                line = line.split()
                q_id = line[0]
                d_id = line[2]
                id = d_id.split("-")
                # 0 padding
                # EXAMPLE :
                # CACM-753 is changed to CACM-0753
                if len(id[1]) == 3:
                    dno = "0"+id[1]
                    d_id = id[0]+"-"+dno
                if q_id not in self.RelInfo.keys():
                    self.RelInfo[q_id] = [d_id]
                else:
                    self.RelInfo[q_id].append(d_id)

    # precision(self)
    # EFFECT : calculates the precision values for all top 100
    #          documents for every query and stores the information in
    #          precision_dict
    # WHERE  : key of precision_dict is the query id
    #          value of precision_dict is a dictionary preci_dict
    #          key of preci_dict is the docID
    #          value of preci_dict is the precision value
    #          precision_value = number of relevant documents retrieved so far/
    #                     number of documents retrieved so far

    def precision(self):
        for q in self.doc_dict.keys():
            relevant_soFar = 0
            retrieved_soFar = 0
            dict = self.doc_dict[q]
            for doc in dict.keys():
                if q in self.RelInfo.keys():
                    if doc in self.RelInfo[q]:
                        relevant_soFar = relevant_soFar + 1
                retrieved_soFar = retrieved_soFar + 1
                precision_value = relevant_soFar/retrieved_soFar
                preci_dict = OrderedDict()
                preci_dict[doc] = precision_value
                if q in self.precision_dict.keys():
                    dict = self.precision_dict[q]
                    dict.update(preci_dict)
                    self.precision_dict[q] = dict
                else:
                    self.precision_dict[q] = preci_dict


    # recall(self)
    # EFFECT : calculates the recall values for all top 100
    #          documents for every query and stores the information in
    #          recall_dict
    # WHERE  : key of recall_dict is the query id
    #          value of recall_dict is a dictionary rec_dict
    #          key of rec_dict is the docID
    #          value of rec_dict is the recall value
    #          recall_value = number of relevant documents retrieved so far/
    #                         total number of relevant documents retrieved

    def recall(self):
        for q in self.doc_dict.keys():
            relevant_soFar = 0
            retrieved_soFar = 0
            if q in self.RelInfo.keys():
                total_relevant = len(self.RelInfo[q])
            else:
                total_relevant = 0
            dict = self.doc_dict[q]
            for doc in dict.keys():
                if q in self.RelInfo.keys():
                    if doc in self.RelInfo[q]:
                        relevant_soFar = relevant_soFar + 1
                retrieved_soFar = retrieved_soFar + 1
                if total_relevant == 0:
                    rec = 0
                else:
                    rec = relevant_soFar/total_relevant
                rec_dict = OrderedDict()
                rec_dict[doc] = rec
                if q in self.recall_dict.keys():
                    dict = self.recall_dict[q]
                    dict.update(rec_dict)
                    self.recall_dict[q] = dict
                else:
                    self.recall_dict[q] = rec_dict


    # map_file(self, rankfile)
    # GIVEN  : rankfile is the path of the file that containds the ranklist
    # EFFECT : creates a file that contains the MAP values of every query

    def map_file(self,rankfile,evalFile):
        file = evalFile+"/"+"MAP_" + rankfile
        f = open(file,'w')
        for q in self.map_dict.keys():
            f.write(q+" "+str(self.map_dict[q])+"\n")
        f.close()


    # map(self)
    # EFFECT : creates a map_dict which contains the MAP values of every query
    # WHERE  : key of map_dict is the queryID
    #          value of map_dict is the MAP value of the query
    #          map_value (of a query) = (sum of precision values of all
    #                                   relevant documents)/
    #                                   (total number of relevant documents
    #                                   retrieved)

    def map(self):
        for q in self.RelInfo.keys():
            total_relevant = 0
            total_preci = 0
            for doc in self.RelInfo[q]:
                dict = self.precision_dict[q]
                for d in dict.keys():
                    if doc == d:
                        total_preci = total_preci + dict[d]
                        total_relevant = total_relevant + 1
            if total_relevant == 0:
                map_val =0
            else:
                map_val = total_preci/total_relevant
            self.map_dict[q] = map_val



    # mrr_file(self, rankfile)
    # GIVEN  : rankfile is the path of the file that containds the ranklist
    # EFFECT : creates a file that contains the MRR values of every query

    def mrr_file(self, rankfile, evalFile):
        file = evalFile+"/"+"MRR_" + rankfile
        f = open(file,'w')
        for q in self.mrr_dict.keys():
            f.write(q+" "+str(self.mrr_dict[q])+"\n")
        f.close()

    # mrr(self)
    # EFFECT : creates a mrr_dict which contains the MRR values of every query
    # WHERE  : key of mrr_dict is the queryID
    #          value of mrr_dict is the MRR value of the query
    #          mrr_value (of a query) = 1 /
    #                                   (rank of first relevant document
    #                                   retrieved)

    def mrr(self):
        for q in self.RelInfo.keys():
            dict = self.doc_dict[q]
            rank_list = []
            for doc in self.RelInfo[q]:
                if doc in dict.keys():
                    rank_list.append(dict[doc])
            rank_list.sort()
            if len(rank_list) == 0:
                mrr_val = 0
            else:
                first_relevant = rank_list[0]
                mrr_val = 1/int(first_relevant)
            self.mrr_dict[q] = mrr_val



    # precison_file(self, rankfile)
    # GIVEN  : rankfile is the path of the containing the ranklist
    # EFFECT : creates a Precision file by writing the content of
    #          precision_dict

    def precision_file(self,rankfile, evalFile):
        file = evalFile+"/"+"Precision_"+rankfile
        f = open(file,'w')
        for k in self.precision_dict.keys():
            f.write(k+" ")
            dict = self.precision_dict[k]
            for d in dict.keys():
                f.write(str(dict[d])+" ")
            f.write("\n")
        f.close()


    # recall_file(self, rankfile)
    # GIVEN  : rankfile is the path of the containing the ranklist
    # EFFECT : creates a Recall file by writing the content of
    #          recall_dict

    def recall_file(self, rankfile, evalFile):
        file = evalFile+"/"+"Recall_" + rankfile
        f = open(file, 'w')
        for k in self.recall_dict.keys():
            f.write(k + " ")
            dict = self.recall_dict[k]
            for d in dict.keys():
                f.write(str(dict[d]) + " ")
            f.write("\n")
        f.close()

    # write_to_file(self, rankfile)
    # GIVEN  : rankfile is the path of the file containing the ranklist
    # EFFECT : calls precision_file(), recall_file(), map_file() and mrr_file()

    def write_to_file(self, rankfile, evalFile):
        self.precision_file(rankfile, evalFile)
        self.recall_file(rankfile, evalFile)
        self.mrr_file(rankfile, evalFile)
        self.map_file(rankfile, evalFile)



    def precision_at_k(self,k,rankfile, evalFile):
        pAtK_dict = OrderedDict()
        item = list(self.precision_dict.items())
        for q in self.precision_dict.keys():
            dict = self.precision_dict[q]
            items = list(dict.items())
            d = items[k-1]
            pAtK_dict[q] = d[1]
        fname = evalFile+"/"+"Precision_At_"+str(k)+"_"+rankfile
        fhandle = open (fname, 'w')
        for key in pAtK_dict.keys():
            fhandle.write(key+" : "+str(pAtK_dict[key])+"\n")
        fhandle.close()


    # perform_evaluation(self, rankfileAbs, relevanceFile, rankfile)
    # GIVEN  : rankfileAbs is the path of file that contains the ranklist,
    #          relevanceFile is the path of the file that contains the
    #          relevance information
    #          rankfile is the name of the file that contains the ranklist
    # EFFECT : calls get_ranklist(), get_relevance_info(), precision(),
    #          recaall(), map(), mrr(), write_to_file()
    # WHERE  : rankfileAbs is the absolute path of the file

    def perform_evaluation(self, rankfileAbs, relevanceFile, rankfile, evalFile):
        self.get_ranklist(rankfileAbs)
        self.get_relevance_info(relevanceFile)
        self.precision()
        self.recall()
        self.map()
        self.mrr()
        self.write_to_file(rankfile, evalFile)


def main():
    print ("Enter the absolute path to the folder containing the output of the 8 runs ")
    folder = input()
    print ("Enter the absolute path of file containing relevance information ")
    relevanceFile = input()
    print ("Enter the absolute path of the folder to create the evaluation output files ")
    evalFile = input()
    for file in os.listdir(folder):
        eval = Evaluation()
        rankfileAbs = folder+"/"+file
        eval.perform_evaluation(rankfileAbs, relevanceFile, file, evalFile)
        eval.precision_at_k(5, file, evalFile)
        eval.precision_at_k(20, file, evalFile)

main()
