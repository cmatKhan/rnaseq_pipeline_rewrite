#!/usr/bin/env bash

# TODO: FIND BETTER WAY OF DOING DOCSTRING/HELP
#  wrapper for htseq-count
#  usage: 
#  author: chase mateusiak chase.mateusiak@gmail.com
#  htseq-counts documentation: https://htseq.readthedocs.io/en/release_0.11.1/count.html

#  input:
#      -h --help should display this docstring
#      -b --path to sam file
#      -a --annotation_file_gtf to annotation file (gtf)
#      -t --feature_type see flag specification at https://htseq.readthedocs.io/en/release_0.11.1/count.html
#      -i --id_attribute see flag specification at https://htseq.readthedocs.io/en/release_0.11.1/count.html
#      -s --strandedness of library ('yes', 'reverse' or 'no') see flag specification at https://htseq.readthedocs.io/en/release_0.11.1/count.html
#      -o --output_file_name 

#   output: -o ${output_file_name}_htseq_annote.sam (this is a file with the same number of lines as the input bam and gives a flag eg XF:CNAG_12345 for the feature count to which the read contributed)
#           1> ${output_file_name}_read_count.tsv
#           2> ${output_file_name}_htseq.log

last_line_docstring=20

# utils.sh needs to be in the same directory as this script
SOURCEDIR="$(dirname "$(realpath "$0")")"
source ${SOURCEDIR}/utils.sh

main(){
    # main method, called at bottom of script after all functions read in

    # parse cmd line input
    parseArgs "$@"
    # verify cmd line input
    checkInput
    # check that necessary software is available
    checkPath htseq-count "RunHtseqCountsError: htseq-count not found in PATH"

    htseq-count -f bam \
                -o ${output_file_name}_htseq_annote.sam \
                -s ${strandedness} \
                -t ${feature_type} \
                -i ${id_attribute} \
                ${bam} \
                ${annotation_file_gtf} \
                1> ${output_file_name}_read_count.tsv \
                2> ${output_file_name}_htseq.log 
}

checkInput(){
  # check input, raise errors
  # TODO: should this go to >2 or >1?
  if [[ ! -e $bam ]]; then
      echo "RunHtseqCountsInputError: bam ${bam} does not exist"
      exit 1
  fi
  if [[ ! -e $annotation_file_gtf ]]; then
      echo "RunHtseqCountsInputError: annotation file ${annotation_file_gtf} does not exist"
      exit 1
  fi
  if [[ !(${bam#*.} == bam )  ]]; then
      echo "RunHtseqCountsInputError: sam file does not end in .sam. Are you sure this is a sam file?"
      exit 1
  fi
  # TODO: add error checking -- should not include any periods
  if [[ -z $output_file_name ]]; then
      echo "RunHtseqCountsInputError: output_file_name not specified"
      exit 1
  fi
  if [[ -z $feature_type ]]; then
      echo "RunHtseqCountsInputError: feature_type not specified"
      exit 1
  fi
  if [[ -z $id_attribute ]]; then
      echo "RunHtseqCountsInputError: id_attribute not specified"
      exit 1
  fi 
  if [[ -z $strandedness ]]; then
      echo "RunHtseqCountsInputError: strandedness not specified"
      exit 1
  fi
}

parseArgs(){
  #    parse cmd line input, set global variables
  #    usage: Assuming this is called from main, and the entire cmd line argument array was passed to main, parseArgs "$@"
  #    input: cmd line input passed in main method via $@

  while [[ "$1" =~ ^- && ! "$1" == "--" ]]; do case $1 in
    -h | --help )
      head -${last_line_docstring} $0
      exit
      ;;
    -f | --bam )
      shift; bam=$1
      ;;
    -a | --annotation_file_gtf )
      shift; annotation_file_gtf=$1
      ;;
    -t | --feature_type )
      shift; feature_type=$1
      ;;
    -i | --id_attribute )
      shift; id_attribute=$1
      ;;
    -s | --strandedness )
      shift; strandedness=$1
      ;;
    -o | --output_file_name )
      shift; output_file_name=$1
      ;;
  esac; shift; done
  if [[ "$1" == '--' ]]; then shift; fi

}

main "$@"