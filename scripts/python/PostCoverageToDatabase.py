    #!/usr/bin/env python

    # TODO: generalize this into a function with variable id, data columns?

    # standard library imports
    from sys import exit
    from json import json.dumps as json.dumps
    import argparse
    from urllib.request import HTTPError

    # third party imports
    import pandas as pd
    
    # local imports
    from .rnaseq_tools.utils import postData

    def main(argv){
        
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
        #######################################################################################
        
        # read in count file
        count_file_df = pd.read_csv(args.count_file, sep='\t', names=[htseq_output_first_col_name, args.sample_name])

        # remove the htseq qc info at the bottom of the file (it starts with __, eg __ambiguous)
        gene_counts = count_file_df[~count_file_df.htseq_col.str.startswith(qc_metric_identifier)]
        # write out the counts
        gene_counts.to_csv("%s_%s.csv" %(args.sample_name, count_suffix), index=False)

        # extract the qc rows
        htseq_qc_data = count_file_df[count_file_df.htseq_col.str.startswith(qc_metric_identifier)]
        # write out the qc data
        htseq_qc_data.to_csv("%s_%s.csv" %(args.sample_name, qc_suffix), index=False)

        # get the count dict in structure {fastqFileName: [counts]}
        gene_count_dict = gene_counts.drop([htseq_output_first_col_name], axis=1).to_dict(orient="list")

        # this is the body of the request. fastqFileNumber is the foreign key of Counts
        data = {'fastqFileNumber': args.fastq_file_number, 'rawCounts': json.dumps(gene_count_dict)}

        # try to send count data to database, exit with error message if fail
        try:
            utils.postData(args.url, data)
        except(HTTPError):
            exit('PostCountsToDatabaseError: fastqfilenumber %s failed to update %s' %(fastq_file_number, url)

    }

    def parseArgs(argv):
        parser = argparse.ArgumentParser(description="This script summarizes the output from pipeline wrapper.")
        parser.add_argument("-c", "--count_file", required=True,
                            help="[REQUIRED] Directory with files in the following subdirectories: align, count, logs. Output from raw_count.py and log2cpm.R must be in count directory.")
        parser.add_argument("-n", "--sample_name",
                            help="[REQUIRED] Should be unique. Suggestion: use the fastq name stripped of path and file extension")
        parser.add_argument("-i", "--fastq_file_number",
                            help="[REQUIRED] fastqFileNumber, the foreign key of QualityAssessment table which links back to FastqFiles table")
        parser.add_argument("-u", "--url",
                            help="[REQUIRED] URL to which to post data (this is purpose built for counts, so it should be https://someaddress/Counts/")
        args = parser.parse_args(argv[1:])
        return args

if __name__ == "__main__":
main(sys.argv)

