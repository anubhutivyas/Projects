from context import Context
from BM25WithRelevance import BM25WithRelevance
from  tf_idf import Tf_idf
from indexer import Indexer
from create_corpus import Create_corpus
from QueryParser import Query_Parser
from QL import QueryLikelihood
from Task3 import Task3
from SnippetGeneration import SnippetGeneration
#from Evaluation import Evaluation
from file_path import File_path
from PseudoRelFeedback import PseudoRelFeedback

def main():
   # File_path is a class that stores the file paths for required documents.
    f = File_path()
    f.declare_paths()
    corpus = Create_corpus(f.raw_files_folder, True, True)
    corpus.parse_files(f.raw_files_folder, f.parsed_file_folder, True , True)

    a = Indexer()
    a.create_unigram_index(f.parsed_file_folder,f.index_file_path)

    c = Context()
    index = c.read_inverted_index(f.index_file_path)
    DL = c.calculate_document_length(f.parsed_file_folder)
    AvDL = c.calculate_avg_doc_length(f.parsed_file_folder)
    q = Query_Parser()
    q.parse_queries(f.query_file_path,f.parsed_query_file_path)

    f1 = open(f.parsed_query_file_path,"r")
    query = dict()
    for lines in f1:
        lines = lines.split(":")
        query[lines[0]] = lines[1].strip()
    bm = BM25WithRelevance("BM25WithRelevance")
    bm.retrieve_bm25_scores(query,f.parsed_file_folder,AvDL,DL,index, f.relevance_file_path, f.output_folder_path)

    tf = Tf_idf("TfIdfRanking")
    tf.retrieve_tfidf_scores(DL,query,index,f.output_folder_path)

    q = QueryLikelihood("QLModel")
    q.retrieve_QL_scores(DL, query,index,f.output_folder_path)

   # task 2 - pseudo relevance feedback
    pr = PseudoRelFeedback()
    pr.PRmain(f.parsed_file_folder,f.index_file_path,f.parsed_query_file_path,f.relevance_file_path,f.stop_file_path,f.output_folder_path)

    # task 3 - stemmed queries
    t = Task3()
    t.driver_stemmed(f)
    t.ranking_with_stopwords(f)

    # phase 2 - Snippet generation
    sg = SnippetGeneration(f.raw_files_folder)
    sg.get_queries(f.parsed_query_file_path)
    output_file_path = f.output_folder_path+"/"+"BM25WithRelevance"+".txt"
    sg.get_ranklist(output_file_path)
    sg.generate_snippet(f.snippet_file)

main()