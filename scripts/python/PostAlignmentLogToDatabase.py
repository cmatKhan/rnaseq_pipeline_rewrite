#!/usr/bin/env python

"""
    Parse novoalign log, write out qc and post to database
    usage:
    author: chase.mateusiak@gmail.com
    output: {'librarySize': 35003, 'uniqueAlignment': 22737, 'multiMap': 1986, 'noMap': 10233, 'homopolymerFilter': 47, 'readLengthFilter': 0}

    output: parsed novoalign log as csv
    database_interaction: post to url
"""

# standard library imports
import sys
import os
import re
from json import dumps as json_dumps
import argparse
import request
from urllib.request import HTTPError

# third party imports
import pandas as pd

# extend python path to include utils dir
sys.path.extend([os.path.join(os.path.realpath(__file__), 'utils')])

# local imports
from utils.DatabaseInteraction import postData

def main(argv):

    # parse cmd line arguments
    args = parseArgs(argv)

    ################################ set name variables ###################################
    # name for the first of the two columns in the htseq output. The first column contains
    # the gene ids, but also a number of rows at the bottom that start with __ and contain
    # qc metrics
    htseq_output_first_col_name = "gene_id"
    # the htseq identifier of qc metric rows (bottom of first column)
    qc_metric_identifier = "__"
    # suffix to append to the sample_name to output qc file
    qc_suffix = "htseq_qc"
    # suffix to append to count file output
    count_suffix = "counts"
    # names of the columns (there are three)
    col_names = ['chr', 'bp', 'depth']
    #######################################################################################

    # get the filename from the coverage file
    novoalign_qc_dict = 

    # read in count file
    coverage_df = pd.read_csv(args.coverage_file, sep='\t', names=col_names)

    # get the count dict in structure {fastqFileName: [counts]}
    coverage_row_dict = coverage_df.to_dict(orient="records")
    
    coverage_dict = {}
    coverage_dict.setdefault(sample_name, coverage_row_dict)

    # this is the body of the request. fastqFileNumber is the foreign key of Counts
    data = {'fastqFileNumber': args.fastq_file_number, 'coverage': json_dumps(gene_count_dict)}

    # try to send count data to database, exit with error message if fail
    if args.post:
        try:
            postData(args.url, data)
        except(HTTPError):
            exit('PostCountsToDatabaseError: fastqfilenumber %s failed to update %s' %(fastq_file_number, url))

def parseAlignmentLog(alignment_log_file_path):
    """
        parse the information on the alignment out of a novoalign log
        :param alignment_log_file_path: the filepath to a novoalign alignment log
        :returns: a dictionary of the parsed data of the input file
    """
    library_metadata_dict = {}
    alignment_regex_dict = {'librarySize': r"(?<=Read Sequences:\s)\s*\d*",
                            'uniqueAlignment': r"(?<=Unique Alignment:\s)\s*\d*",
                            'multiMap': r"(?<=Multi Mapped:\s)\s*\d*",
                            'noMap': r"(?<=No Mapping Found:\s)\s*\d*",
                            'homopolymerFilter': r"(?<=Homopolymer Filter:\s)\s*\d*",
                            'readLengthFilter': r"(?<=Read Length:\s)\s*\d*"}

    # open the log path
    alignment_file = open(alignment_log_file_path, 'r')
    alignment_file_text = alignment_file.read()
    # loop over alignment_regex dict and enter values extracted from alignment_file into alignment_metadata_dict
    for alignment_category, regex_pattern in alignment_regex_dict.items():
        # extract the value corresponding to the alignment_category regex (see alignment_regex_dict)
        try:
            extracted_value = int(re.findall(regex_pattern, alignment_file_text)[0])
        except ValueError:
            msg = 'problem with file %s' % alignment_log_file_path
            print(msg)
        except IndexError:
            print('No %s in %s. Value set to 0' % (alignment_category, alignment_log_file_path))
            extracted_value = 0
        # check that the value is both an int and not 0
        if isinstance(extracted_value, int):
            library_metadata_dict.setdefault(alignment_category, extracted_value)
        else:
            print('cannot find %s in %s' % (alignment_category, alignment_log_file_path))

    # close the alignment_file and return
    alignment_file.close()

    return library_metadata_dict

def parseArgs(argv):
    parser = argparse.ArgumentParser(description="This script summarizes the output from pipeline wrapper.")
    parser.add_argument("-c", "--count_file", required=True,
                        help="[REQUIRED] Directory with files in the following subdirectories: align, count, logs. Output from raw_count.py and log2cpm.R must be in count directory.")
    parser.add_argument("-n", "--sample_name", required=True,
                        help="[REQUIRED] Should be unique. Suggestion: use the fastq name stripped of path and file extension")
    parser.add_argument("-i", "--fastq_file_number", required=True,
                        help="[REQUIRED] fastqFileNumber, the foreign key of QualityAssessment table which links back to FastqFiles table")
    parser.add_argument("-u", "--url", required=True,
                        help="[REQUIRED] URL to which to post data (this is purpose built for counts, so it should be https://someaddress/Counts/")
    parser.add_argument('--post', dest='post', action='store_true',
                        help="[DEFAULT TRUE] default behavior is to post to the database. set --no-post to avoid this")
    parser.add_argument('--no-post', dest='post', action='store_false',
                        help="See --post. Set --no-post to prevent posting the data to the url")
    
    parser.set_defaults(post=True)
    args = parser.parse_args(argv[1:])
    
    return args


if __name__ == "__main__":
    main(sys.argv)
