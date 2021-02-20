#!/usr/bin/env python

"""
    Parse htseq output (two columns first locus, second count) and output/send to database
    usage:
    author: chase.mateusiak@gmail.com

    output: ${sample_name}_counts.csv, ${sample_name}_htseq_qc.csv
    database_interaction: post to url
"""

# TODO: generalize this into a function with variable id, data columns?

# standard library imports
import sys
import os
from json import dumps as json_dumps
import argparse
import requests
from urllib.request import HTTPError

# extend python path to include utils dir
sys.path.extend([os.path.join(sys.path[0], 'utils')])

# third party imports
import pandas as pd

# local imports
from utils.DatabaseInteraction import postData

def main(argv):
    """[summary]

    :param argv: [description]
    :type argv: [type]
    """

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
    # count_file_df column names
    col_names=[htseq_output_first_col_name, args.sample_name]\
    # for parsing the qc metrics
    qc_column_dict = {'__no_feature': 'noFeature', '__ambiguous': 'ambiguous',
                    '__too_low_aQual': 'tooLowAqual', '__not_aligned': 'notAligned', 
                    '__alignment_not_unique': 'alignmentNotUnique'}
    # for post data
    primary_key = 'fastqFileNumber'
    data_column = 'rawCounts'
    #######################################################################################

    # read in count file
    count_file_df = pd.read_csv(args.count_file, sep='\t', names=col_names)

    # remove the htseq qc info at the bottom of the file (it starts with __, eg __ambiguous)
    gene_counts = count_file_df[~count_file_df[htseq_output_first_col_name].str.startswith(qc_metric_identifier)]
    # write out the counts
    gene_counts.to_csv("%s_%s.csv" %(args.sample_name, count_suffix), index=False)

    # extract the qc rows
    htseq_qc_data = count_file_df[count_file_df[htseq_output_first_col_name].str.startswith(qc_metric_identifier)]
    # write out the qc data
    htseq_qc_data.to_csv("%s_%s.csv" %(args.sample_name, qc_suffix), index=False)

    # get the count dict in structure {fastqFileName: [counts]}
    gene_count_dict = gene_counts.drop([htseq_output_first_col_name], axis=1).to_dict(orient="list")

    # this is the body of the request. fastqFileNumber is the foreign key of Counts
    count_data = {primary_key: str(args.fastq_file_number), data_column: json_dumps(gene_count_dict)}

    # try to send count data to database, exit with error message if fail
    if args.post:
        try:
            postData(args.counts_url, count_data)
        except Exception as e:
            exit('PostCountsToDatabaseError: fastqfilenumber %s failed to update %s for reason %s' %(args.fastq_file_number, args.counts_url, e))

    # parse qc rows into a dict
    qc_dict = qcMetricsToDict(htseq_qc_data, qc_column_dict, args.fastq_file_number)

    # try to send qc to database, exit with error if fail
    if args['post']:
        try:
	    r = requests.post(args.qc_url, data=qc_dict)
	    r.raise_for_status()
        except requests.HTTPError as exception:
	    try:
	        r = requests.put(args.qc_url+str(args.fastq_file_number.)+'/', data=qc_dict)
	        r.raise_for_status()
	    except requests.HTTPError as e:
	        exit('PostCountsToDatabaseError: could not post or put %s to %s for reason %s' %(args.fastq_file_number, args.qc_url, e))

def qcMetricsToDict(htseq_qc_data, qc_column_dict, sample_number):
    """
    parsed from the htseq counts, this has headings the same as the counts df
    :params htseq_qc_data: the qc rows parsed from the bottom of the htseq output
    """
    qc_dict = {'fastqFileNumber': str(sample_number)}

    for index, row in htseq_qc_data.iterrows():
        qc_metric = row[0]
        try:
            qc_dict.setdefault(qc_column_dict[qc_metric], row[1])
        except KeyError:
            sys.exit("HtseqQualityMetricParsingError: QC metric not in database columns")
    
    return qc_dict



def parseArgs(argv):
    parser = argparse.ArgumentParser(description="This script summarizes the output from pipeline wrapper.")
    parser.add_argument("-c", "--count_file", required=True,
                        help="[REQUIRED] Directory with files in the following subdirectories: align, count, logs. Output from raw_count.py and log2cpm.R must be in count directory.")
    parser.add_argument("-n", "--sample_name", required=True,
                        help="[REQUIRED] Should be unique. Suggestion: use the fastq name stripped of path and file extension")
    parser.add_argument("-i", "--fastq_file_number", required=True,
                        help="[REQUIRED] fastqFileNumber, the foreign key of QualityAssessment table which links back to FastqFiles table")
    parser.add_argument("-cu", "--counts_url", required=True,
                        help="[REQUIRED] URL to which to post data (this is purpose built for counts, so it should be https://someaddress/Counts/")
    parser.add_argument("-qu", "--qc_url", required=True,
                        help="[REQUIRED] URL to which to post data (this is purpose built for counts, so it should be https://someaddress/QualityAssess/")
    parser.add_argument('--post', dest='post', action='store_true',
                        help="[DEFAULT TRUE] default behavior is to post to the database -- no need to include this flag. set --no-post to avoid this")
    parser.add_argument('--no-post', dest='post', action='store_false',
                        help="See --post. Set --no-post to prevent posting the data to the url")
    
    parser.set_defaults(post=True)
    args = parser.parse_args(argv[1:])
    
    return args

if __name__ == "__main__":
    main(sys.argv)

