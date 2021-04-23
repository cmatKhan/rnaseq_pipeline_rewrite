#!/usr/bin/env python

"""
    parse coverage .bed into a json and post to database
    usage:
    author: chase.mateusiak@gmail.com

    database_interaction: post to url
"""

# SYSTEM DEPENDENCIES
# gff2bed, samtools, grep, bedtools

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
    feature = "CDS"
    nat_bases_in_cds = 606
    g418_bases_in_cds = 795
    #######################################################################################

    # calculate marker coverages
    nat_coverage = self.calculatePercentFeatureCoverage(feature, 'CNAG_NAT',args.annotation_file, args.bam_file, nat_bases_in_cds)
    g418_coverage = self.calculatePercentFeatureCoverage(feature, 'CNAG_G418',annotation_file,bam_file, g418_bases_in_cds)

    data = {primary_key: args.fastq_file_number, natCoverage: str(nat_coverage), g418Coverage: str(g418_coverage)}



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


def calculatePercentFeatureCoverage(feature, genotype, annotation_path, bam_file, num_bases_in_region=None):
    """
        Calculate percent of given feature (regions summed, so all exon in gene, eg) of a gene (exon, CDS, etc) covered by 1 or more reads
        :param feature: annotation feature over which to take percentage, eg all exons in gene, or all CDS
        :param genotype: gene in annotation file
        :param annotation_path: path to annotation file
        :param bam_file: a sorted, indexed alignment file (.bam)
        :param num_bases_in_region: pass number of bases in the region directly, this will skip the step of calculating this number from the annotation file
        :returns: the fraction of bases in the (summed over the number of features in the gene) feature region covered by at least one read
    """
    if not num_bases_in_region:
        # extract number of bases in CDS of given gene. Credit: https://www.biostars.org/p/68283/#390427
        num_bases_in_region_cmd = "grep %s %s | grep %s | bedtools merge | awk -F\'\t\' \'BEGIN{SUM=0}{ SUM+=$3-$2 }END{print SUM}\'" % (
            genotype, annotation_path, feature)
        self.logger.info(' num bases in region cmd: %s' %num_bases_in_region_cmd)
        num_bases_in_region = int(subprocess.getoutput(num_bases_in_region_cmd))
    # extract number of bases with depth != 0
    num_bases_depth_not_zero_cmd = "grep %s %s | grep %s | gff2bed | samtools depth -aa -Q 10 -b - %s | cut -f3 | grep -v 0 | wc -l" % (
        genotype, annotation_path, feature, bam_file)
    self.logger.info(' num bases depth not zero over region cmd: %s' % num_bases_depth_not_zero_cmd)
    num_bases_in_cds_with_one_or_more_read = int(subprocess.getoutput(num_bases_depth_not_zero_cmd))

    return num_bases_in_cds_with_one_or_more_read / float(num_bases_in_region)