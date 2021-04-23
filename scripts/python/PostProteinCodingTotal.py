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
    locus_identifier = 'gene_id'
    primary_key = 'fastqFileNumber'
    data_column = 'proteinCodingCounted'
    #######################################################################################

    counts_df = pd.read_csv(args.count_file)

    protein_coding_counts_df = counts_df[counts_df[locus_identifier].str.startswith("CKF44_")]
    protein_coding_counted = protein_coding_counts_df.iloc[:,1].sum()

    # this is the body of the request. fastqFileNumber is the foreign key of Counts
    data = {primary_key: args.fastq_file_number, data_column: str(protein_coding_counted)}

    # try to send count data to database, exit with error message if fail
    if args.post:
        try:
	    r = requests.post(args.url, data=data)
	    r.raise_for_status()
        except requests.HTTPError as exception:
	    try:
	        r = requests.put(args.qc_url+str(args.fastq_file_number.)+'/', data=data)
	        r.raise_for_status()
	    except requests.HTTPError as e:
	        exit('PostCountsToDatabaseError: could not post or put %s to %s for reason %s' %(args.fastq_file_number, args.qc_url, e))

def parseArgs(argv):
    parser = argparse.ArgumentParser(description="This script summarizes the output from pipeline wrapper.")
    parser.add_argument("-c", "--count_file", required=True,
                        help="[REQUIRED] htseq output as csv PARSED so only gene counts (no qc) are included")
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

