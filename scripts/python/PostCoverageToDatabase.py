#!/usr/bin/env python

"""
    parse coverage .bed into a json and post to database
    usage:
    author: chase.mateusiak@gmail.com

    database_interaction: post to url
"""

# standard library imports
import sys
import os
from json import dumps as json_dumps
import argparse

# extend python path to include utils dir
sys.path.extend([os.path.join(os.path.realpath(__file__), 'utils')])

# third party imports
import pandas as pd

# local imports
from utils.DatabaseInteraction import postData

def main(argv):

    # parse cmd line arguments
    args = parseArgs(argv)

    ################################ set name variables ###################################
    # names of the columns (there are three)
    col_names = ['chr', 'bp', 'depth']
    # for post data
    primary_key = 'fastqFileNumber'
    data_column = 'coverage'
    #######################################################################################

    # get the filename from the coverage file
    sample_name = args.coverage_file.replace("_coverage.bed", "")

    # read in count file
    coverage_df = pd.read_csv(args.coverage_file, sep='\t', names=col_names)

    # get the count dict in structure {fastqFileName: [counts]}
    coverage_row_dict = coverage_df.to_dict(orient="records")
    
    coverage_dict = {}
    coverage_dict.setdefault(sample_name, coverage_row_dict)

    # this is the body of the request. fastqFileNumber is the foreign key of Counts
    data = {primary_key: args.fastq_file_number, data_column: json_dumps(coverage_dict)}
    print(data)

    # try to send count data to database, exit with error message if fail
    if args.post:
        try:
            postData(args.url, data)
        except Exception as e:
            exit('PostCountsToDatabaseError: fastqfilenumber %s failed to update %s for reason %s' %(fastq_file_number, url, e))

def parseArgs(argv):
    parser = argparse.ArgumentParser(description="This script summarizes the output from pipeline wrapper.")
    parser.add_argument("-c", "--coverage_file", required=True,
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

