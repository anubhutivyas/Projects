INTRODUCTION:

In this project, a Web-based Search Engine is designed and built. This project has 6 parts; the Parser, the Indexer, the Search Engine, Feedback, Result Display and Evaluation.

1. PARSING:
Parsing of corpus is done in 3 ways:

a. Default - Documents are case folded and punctuations are removed
b. Stopping - Documents are case folded, punctuations are removed and stop words are removed as per the list of given common words.
c. Stemmed - The stemmed documents file provided is broken down into multiple files and stored in a folder
This results in 3 parsed corpuses - Default, Stopped, Stemmed(provided)
Query file is parsed by performing stopping, removing punctuations and case-folding.

2. INDEXING:
A unigram indexer is built for every version of the parsed documents.

3. FEEDBACK:
The top 10 ranked documents in first round of baseline run are assumed to be relevant; query is expanded by using 5 most frequent words (after removing stop words) and the revised list of top ranked documents is displayed.

4. SCORING AND RANKING:
The documents are retrieved using 4 baseline runs:
a. Lucene’s default retrieval model.
b. BM25, with relevance feedback
c. Tf-idf
d. Query Likelihood

For default parsed documents, the default parsed version of queries is used, that is case folded and without punctuations.
For stopped documents, while retrieving top documents queries are also stopped.
For stemmed corpus provided, stemmed queries are used.

5. RESULT AND DISPLAY
4 baseline runs with default parsing:
For each baseline run, a table is created with the top 100 ranked documents for each query for that particular run

6. EVALUATION:
Following evaluation measures of Information Retrieval techniques are calculated to access the performance of the built retrieval system:
I. Precision
II. Recall
III. MAP (Mean Average Precision)
IV. MRR (Mean Reciprocal Rank)
V. P@K (K=5 and K=20)



PSEUDO RELEVANCE FEEDBACK:

For the relevance feedback run, a table is created based with revised list of top 100 documents for each expanded query.
3 Baseline runs with stopping:
A table is created for each run with top 100 ranked documents for each query.
3 Baseline runs with stemming:
A table is created for each run with top 100 ranked documents for each query.



SNIPPET GENERATION AND QUERY TERM HIGHLIGHTING:

A file is created for each table of baseline run which contains the top 100 documents with their snippets for every query.



INSTRUCTIONS TO RUN AND COMPILE:

To run the program, open the terminal and navigate to the src folder of the project
.
Run main.py by entering the command - "python3 main.py
". The user is asked to enter three paths

1. the path of the "cacm_root_folder"
. It consists of,
-- a folder named "cacm", which consists of the raw corpus.
-- file "cacm_stem.txt", which consists of stemmed corpus.
-- file "cacm.query.txt", which consists of the queries.
-- file "cacm_stem.query.txt", contains the stemmed queries in the format "queryId:query"

-- file "cacm.rel.txt", stores the relevance information for each query.
-- file, "common_words.txt", which consists of a list of stop words

2. the path of the data folder present in the project submission. Please provide the absolute path. It will house the intermediate data like,
-- parsed corpus(The sub directories are already created)

-- stemmed coprus
-- stopped corpus
-- index for default parsed corpus
-- index for stemmed corpus
-- index for stopped corpus
-- The snippet file, consisting of snippets generated for each query.

3. the path of the output files folder which will store the ranking outputs.

 


-- The ranking output files are stored in data/system_name.txt every ranking run. Total of 9 files for the ranking output [3 baseline runs x 3 variations(default parsed, stopping, stemming)]. The ranking outputs are stored in a txt file in the following format, "
QueryId Q0 DocId rank score system_name".


The snippet file is stored in data/snippets.txt, consisting of snippets generated for each query.



EVALUATION:

INSTRUCTIONS TO RUN AND COMPILE:

Run Evaluation.py by entering the command - "python3 Evaluation.py". When prompted,
-- Enter the path where all the output files of the retrivel models are stored
-- Enter the path of the file containing the relevance information
-- Enter the path where all the Evaluation output files are to be stored

OUTPUT:

This contains MRR, MAP, Precision, Recall, Precision at K files for all the output files of below Ranking models
-- 4 Baseline runs
-- Pseudo Relevance Feedback
-- 3 baseline runs x 2 variations (stopping and stemming)




FOR PROXIMITY ENABLED SEARCH:

INSTRUCTIONS TO RUN AND COMPILE:

To run the program, open the terminal and navigate to the src folder of the project
.
Run ProximityEnabledSearchMain.py by entering the command - "python3 ProximityEnabledSearchMain.py
". The user is asked to enter the path of the root folder which contains the whole project.

OUTPUT:

Total of 4 files:
-- "default_proximity_index.txt", contains the index for default parsed files.
-- "stopped_proximity_index.txt", contains the index for stopped files.
-- "NoStopNoStemResults.txt", conatins top 50 results for proximity-enabled search for default parsed files.
-- "StoppedResults.txt", conatins top 50 results for proximity-enabled search for stopped files.



