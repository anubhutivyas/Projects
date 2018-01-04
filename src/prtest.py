from PseudoRelFeedback import PseudoRelFeedback
from file_path import File_path

f = File_path()
pr = PseudoRelFeedback()
pr.PRmain(f.parsed_file_folder,f.index_file_path,f.parsed_query_file_path,f.relevance_file_path)