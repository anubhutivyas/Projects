from stemmed_parser import Stemmed_parser
from context import Context
from BM25WithRelevance import BM25WithRelevance
from tf_idf import Tf_idf
from indexer import Indexer
from QL import QueryLikelihood
from StoppedCorpus import StoppedCorpus
from file_path import File_path

class Task3:
    # driver program or creating the stemmed corpus and ranking them using bm25,tf-idf and QL model
    def driver_stemmed(self,f):
        s = Stemmed_parser(f.stemmed_file, f.stemmed_query_file)
        dict = s.get_stem_documents()
        s.create_files_from_dictionary(dict,f.stemmed_folder_path)
        query = s.create_queryList_stemmed_query(f.stemmed_query_file)
        a = Indexer()
        a.create_unigram_index(f.stemmed_folder_path,f.stemmed_index_file_path)
        c = Context()
        index = c.read_inverted_index(f.stemmed_index_file_path)
        DL = c.calculate_document_length(f.stemmed_folder_path)
        AvDL = c.calculate_avg_doc_length(f.stemmed_folder_path)
        bm = BM25WithRelevance("BM25WithStemming")
        K = bm.calculate_K(f.stemmed_folder_path,AvDL,DL)
        bm.retrieve_bm25_scores(query,f.stemmed_folder_path,AvDL,DL,index, f.relevance_file_path, f.output_folder_path)
        tf = Tf_idf("TfidfWithStemming")
        tf.retrieve_tfidf_scores(DL,query,index,f.output_folder_path)
        ql = QueryLikelihood("QLWithStemming")
        ql.retrieve_QL_scores(DL, query,index,f.output_folder_path)
    

    # driver program for creating the stopped corpus and running the ranking algorithm on the stopped corpus
    def ranking_with_stopwords(self,f):
        s = StoppedCorpus()
        s.stop_corpus(f.stop_corpus_folder_path,f.parsed_file_folder,f.parsed_query_file_path,f.stop_query_path,f.stop_file_path)
        a = Indexer()
        a.create_unigram_index(f.stop_corpus_folder_path,f.stop_index_file_path)
        c = Context()
        index = c.read_inverted_index(f.stop_index_file_path)
        DL = c.calculate_document_length(f.stop_corpus_folder_path)
        AvDL = c.calculate_avg_doc_length(f.stop_corpus_folder_path)
        bm1 = BM25WithRelevance("BM25WithStopping")
        f1 = open(f.parsed_query_file_path,"r")
        query_stopped = dict()
        for lines in f1:
            lines = lines.split(":")
            query_stopped[lines[0]] = lines[1].strip()
        bm1.retrieve_bm25_scores(query_stopped,f.stop_corpus_folder_path,AvDL,DL,index, f.relevance_file_path, f.output_folder_path)

        tf1 = Tf_idf("TfIdfWithStopping")
        tf1.retrieve_tfidf_scores(DL,query_stopped,index,f.output_folder_path)

        q1 = QueryLikelihood("QLModelWithStopping")
        q1.retrieve_QL_scores(DL, query_stopped,index,f.output_folder_path)