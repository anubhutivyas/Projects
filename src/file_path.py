class File_path:
    def __init__(self):
        raw_files_folder = ""
        parsed_file_folder = ""
        query_file_path = ""
        parsed_query_file_path = ""

    def declare_paths(self):
        # takes the root folder path that contains the raw corpus and the queries along with other given files
        self.cacm_root_folder = input("Enter the absolute path of the cacm_root_folder present in the main project folder")
        #self.cacm_root_folder = "/Users/sonalsingh/Desktop/IR/IR_Project/cacm_root_folder"
        self.raw_files_folder = self.cacm_root_folder+ "/cacm"
        self.data_folder = input("Enter the absolute path of the DATA folder in the project, this will store the indexes and the parsed queries")
        self.parsed_file_folder = self.data_folder + "/Parsed_corpus"
        self.index_file_path = self.data_folder + "/index.txt"
        self.query_file_path = self.cacm_root_folder + "/cacm.query.txt"
        self.parsed_query_file_path = self.data_folder+"/parsed_queries.txt"
        self.relevance_file_path = self.cacm_root_folder + "/cacm.rel.txt"
        self.output_folder_path = input("Enter the path of the output folder, this will store all the ranking outputs")

        self.stemmed_file = self.cacm_root_folder + "/cacm_stem.txt"
        self.stemmed_query_file = self.cacm_root_folder + "/cacm_stem.query.txt"
        self.stemmed_folder_path = self.data_folder + "/stemmed_corpus"
        self.stemmed_index_file_path = self.data_folder+"/stemmed_index.txt"
        
        self.stop_query_path = self.data_folder + "/stopped_query.txt"
        self.stop_file_path = self.cacm_root_folder + "/common_words.txt"
        self.stop_corpus_folder_path = self.data_folder+"/stopped_corpus"
        self.stop_index_file_path = self.data_folder+"/stopped_index.txt"
        self.snippet_file = self.data_folder+"/snippets_file.txt"
