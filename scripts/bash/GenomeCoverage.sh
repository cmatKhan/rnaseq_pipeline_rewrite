#!/usr/bin/env bash

# TODO: FIND BETTER WAY OF DOING DOCSTRING/HELP
#  calculate coverage over every bp of genome
#  usage: GenomeCoverage.sh -a /path/to/annotation/file -b /path/to/bam -o output_file_name
#  author: chase mateusiak chase.mateusiak@gmail.com

#  input:
#      -h --help should display this docstring
#      -a --annotation file path
#      -b --bam_file path to bam file
#      -o --output filename NO PERIODS NO FILE EXTENSIONS

#   output: 1> ${output_file_name}_coverage.bed

# utils.sh needs to be in the same directory as this script
source ./utils.sh

# TODO: store gff2bed annotation file output in genome_files

main(){
  # main method, called at bottom of script after all functions read in

  # parse cmd line input
  parseArgs "$@"
  # verify cmd line input
  checkInput
  # check that necessary software is available
  checkPath gff2bed "GenomeCoverageError: gff2bed not found in PATH"
  # check that necessary software is available
  checkPath samtools "GenomeCoverageError: samtools not found in PATH"

  cat $annotation_file_gff | gff2bed | samtools depth -aa -Q 10 -b - $bam_file > ${output_file_name}_coverage.bed

}

checkInput(){
  # check input, raise errors
  # TODO: should this go to 2 or 1?
  if [[ ! -e $annotation_file_gff ]]; then
      echo "GenomeCoverageError: bam_file does not exist"
      exit 1
  fi
  if [[ -z $bam_file ]]; then
      echo "GenomeCoverageError: output_file_name file does not exist"
      exit 1
  fi
  if [[ -z $output_file_name ]]; then
      echo "GenomeCoverageError: output_file_name not specified"
      exit 1
  fi 
}

parseArgs(){
  #    parse cmd line input, set global variables
  #    usage: Assuming this is called from main, and the entire cmd line argument array was passed to main, parseArgs "$@"
  #    input: cmd line input passed in main method via $@

  while [[ "$1" =~ ^- && ! "$1" == "--" ]]; do case $1 in
    -h | --help )
      head -16 $0
      exit
      ;;
    -a | --annotation_file_gff )
      shift; annotation_file_gff=$1
      ;;
    -b | --bam_file )
      shift; bam_file=$1
      ;;
    -o | --output_file_name )
      shift; output_file_name=$1
      ;;
  esac; shift; done
  if [[ "$1" == '--' ]]; then shift; fi

}

main "$@"