import os
from ProximityIndexer import ProximityIndexer
from context import Context
from ProximitySearch import ProximitySearch

def main():
    root_folder_path = input("Enter the path of root folder")

    d3 = root_folder_path + "/ProximityOutput"
    if not os.path.isdir(d3):
        os.mkdir(root_folder_path + "/ProximityOutput")

    output_path = root_folder_path+"/ProximityOutput"

    parsed_file_path = root_folder_path+"/data/parsed_corpus"
    stopped_file_path = root_folder_path+"/data/stopped_corpus"

    parsed_query_file_path = root_folder_path + "/data/parsed_queries.txt"
    stop_query_path = root_folder_path + "/data/stopped_query.txt"

    default_index_path = output_path+ "/default_proximity_index.txt"
    stopped_index_path = output_path + "/stopped_proximity_index.txt"


    #create index from default parsed files
    indexer = ProximityIndexer()
    indexer.generate_inverted_index(parsed_file_path,default_index_path)

    # create index from stopped files
    indexer = ProximityIndexer()
    indexer.generate_inverted_index(stopped_file_path, stopped_index_path)

    #creates a dictionary which contains the length of all the documents
    c = Context()
    DL = c.calculate_document_length(parsed_file_path)

    #calculate scores for the default parsed files
    search = ProximitySearch()
    search.searchDocs(default_index_path,parsed_query_file_path, DL,output_path,"NoStopNoStemProximityTf-Idf")

    # calculate scores for the stopped files
    search = ProximitySearch()
    search.searchDocs(stopped_index_path, stop_query_path, DL,output_path,"StoppedProximityTf-Idf")

main()










