class Stemmed_parser:
    
    # Constructor to create an object of the stemmed parser class
    # takes stem_doc_path : Which is path of the cacm_stem.txt file
    #       stem_query_path : Path of the stemmed query path
    def __init__(self, stem_doc_path , stem_query_path):
        self.stem_document = stem_doc_path
        self.stem_query = stem_query_path

    # Creates a dictionary from the contents of the cacm_stem.txt by splitting at #
    def get_stem_documents(self):
        f = open(self.stem_document,"r")
        content = f.read()
        document_dict = {}
        value = []
        for lines in content.splitlines(True):
            if lines.startswith("#"):
                docId = lines.split()[1]
                continue
            if docId in document_dict.keys():
                val = document_dict[docId]
                document_dict[docId]= val + " " + lines.strip()
            else:
                document_dict[docId] = lines.strip()
            value.clear()
        return document_dict
    
    #GIVEN : dict - It is a dictionary containing the document number as the Key and 
    #               the content of the file as it's value
    #       stemmed_files_folder - The folder path to where the files need to be stored
    #EFFECT : Creates the files from the dictionary and stores them in the folder whose 
    #         path is passed to the function
    def create_files_from_dictionary(self,dict, stemmed_files_folder):
        for files in dict:
            filename = 'CACM-' + files.zfill(4) + ".txt"
            filepath = stemmed_files_folder + "/" + filename
            f = open(filepath,"w")
            f.write(str(dict.get(files)).replace("  ", " "))

    #GIVEN : query_file_path - creates a query dictionary from the given path with the key as the 
    #                          query ID and the value as the stemmed query
    # RETURNS : A dictionary containing the queries along with queryID
    def create_queryList_stemmed_query(self,query_file_path):
        f = open(query_file_path,"r")
        queryList = {}
        queryId = 1
        for queries in f:
            line = queries.split(":")
            queryList[line[0]] = line[1].strip()            
        return queryList