import re
import operator
import os
from bs4 import BeautifulSoup

class SnippetGeneration:
    # DATA DEFINITIONS :
    def __init__(self,raw_files_folder):
        self.dir = raw_files_folder
        
    doc_dict = {}
    dir = "cacm.tar/"
    query_dict = {}
    stop_list = ["what", "when", "where", "which", "how", "why", "a", "an", "the", "for", "of", "in", "by", "and", "is", "on", "to", "or", "that", "this", "it"]
    pattern1 = re.compile(r'((?<!\d)([!%\"#$&\'()*+,.:;<=>\/?@[\]^_`{|}~]+))|([,!@:()\\;.])(?![0-9])|([^\x00-\x7F]+)')
    pattern2 = re.compile(r'([\t\n]+)')


    def get_queries(self, query_file):
        f = open(query_file, 'r')
        queries = f.readlines()
        f.close()
        for q in queries:
            q_list = q.split(':')
            #print (q_list)
            self.query_dict[q_list[0]] = q_list[1]
        #print(query_dict)



    def get_ranklist(self,output_file):
        f = open(output_file, 'r')
        info = f.readlines()
        f.close()
        #print (info)
        for line in info:
            words = line.split()
            #print (words)
            d_dict = {}
            key = words[0]
            d_dict[words[2]] = words[3]
            if key in self.doc_dict.keys():
                dict = self.doc_dict[key]
                dict.update(d_dict)
                self.doc_dict[key] = dict
            else:
                self.doc_dict[key] = d_dict




    def generate_snippet(self,snippet_file):
        for k in self.doc_dict.keys():
            f = open(snippet_file, 'a')
            query = self.query_dict[k]
            f.write("\n" + k + ":" + query + "\n")
            query_terms = query.split()
            terms = [word for word in query_terms if word.lower() not in self.stop_list]
            dictionary = self.doc_dict[k]
            for doc in dictionary.keys():
                sentence_dict = {}
                doc_name = doc.rstrip(".txt")
                doc_name = doc_name + ".html"
                doc_name = self.dir + "/" + doc_name
                f1 = open(doc_name, 'r')
                text = f1.read()
                f1.close()
                soup = BeautifulSoup(text, 'html.parser')
                pre_tags = soup.find('pre')
                doc_info = pre_tags.get_text()
                inf = re.sub(r'(\n)+', '\n', doc_info)
                inf = inf.split("\n")
                title = inf[1]
                f.write("\n" + dictionary[doc] + ". " + title + "\n")
                f.write("\n")
                doc_info = doc_info.replace(title, '')
                doc_info = re.sub(self.pattern2, ' ', doc_info)
                sentences = re.split('(?<!\w\.\w.)(?<![A-Z][a-z]\.)(?<=\.|\?)(\s|[A-Z].*)', doc_info)

                #sentences = sentences[1:]

                for sentence in sentences:
                    if sentence == ' ':
                        continue
                    index_list = []
                    parsed_sentence = re.sub(self.pattern1, '', sentence)
                    parsed_sentence = parsed_sentence.lower()
                    words = parsed_sentence.split()
                    for term in terms:
                        indices = [i for i, x in enumerate(words) if x == term]
                        index_list.extend(indices)
                    index_list.sort()
                    #print(index_list)
                    terms_length = len(index_list)
                    if terms_length == 0:
                        luhn_score = 0
                        #sentence_dict[sentence] = luhn_score
                    else:
                        window_begin = index_list[0]
                        window_end = index_list[terms_length - 1]
                        window = words[window_begin:window_end]
                        window_length = len(window)
                        #print(window)
                        if window_length == 0:
                            luhn_score = 0
                        else:
                            luhn_score = (terms_length ** 2) / window_length
                    sentence_dict[sentence] = luhn_score

                sorted_dict = sorted(sentence_dict.items(), key=operator.itemgetter(1), reverse=True)


                count = 1

                for pair in sorted_dict:

                    if count < 3:
                        sent = pair[0]
                        words = sent.split()
                        for term in terms:
                            for word in words:
                                if word.lower() == term:
                                    sent = sent.replace(word, term.upper())
                        #print(str(sent) + "\tscore: " + str(pair[1]))
                        f.write(str(sent) + "\n")
                    count = count + 1
        f.close()

#def main():
#    sg = SnippetGeneration()
#    sg.get_queries("parsed_query.txt")
#    sg.get_ranklist("Lucene_ranking_cacm.txt")
#    sg.generate_snippet()

#main()