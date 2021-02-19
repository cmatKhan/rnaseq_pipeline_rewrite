#!/usr/bin/env bash

# TODO: FIND BETTER WAY OF DOING DOCSTRING/HELP
#  append the htseq annotation (for the count) to the bam file
#  author: chase mateusiak chase.mateusiak@gmail.com

#  input:
#      -h --help should display this docstring
#      -b --bam_file path to SORTED bam file
#      -s --htseq_annotatations the annotation file output (optionally) by htseq
#      -g --genome path to genome fasta
#      -o --output_file_name NO PERIODS NO FILE EXTENSIONS

#   output: 1> ${output_name}_sorted_annotated.bam

# utils.sh needs to be in the same directory as this script
source ./utils.sh

main(){
  # main method, called at bottom of script after all functions read in

  # parse cmd line input
  parseArgs "$@"
  # verify cmd line input
  checkInput
  # check that necessary software is available
  checkPath samtools "AppendHtseqAnnoteError: samtools not found in PATH"

  samtools view --threads 8 ${sorted_bam} | \\
  paste - $(sed "s/\t//" ${htseq_annotations}) | \\
  samtools view --threads 8 -bS -T ${genome_fasta} > ${output_name}_sorted_annotated.bam
}

checkInput(){
  # check input, raise errors
  # TODO: should this go to 2 or 1?
  if [[ ! -e $sorted_bam_path ]]; then
      echo "AppendHtseqAnnoteInputError: the sam file ${sam_path} does not exist"
      exit 1
  fi
  if [[ ! -e $htseq_annotations ]]; then
      echo "AppendHtseqAnnoteInputError: the sam file ${sam_path} does not exist"
      exit 1
  fi
  if [[ ! -e $genome_fasta ]]; then
      echo "AppendHtseqAnnoteInputError: the sam file ${sam_path} does not exist"
      exit 1
  fi
  if [[ -z $output_file_name ]]; then
      echo "AppendHtseqAnnoteInputError: output_file_name file does not exist"
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
    -b | --sorted_bam_path )
      shift; sorted_bam_path=$1
      ;;
    -s | --htseq_annotations )
      shift; htseq_annotations=$1
      ;;
    -g | --genome_fasta )
      shift; genome_fasta=$1
      ;;
    -o | --output_file_name )
      shift; output_file_name=$1
      ;;
  esac; shift; done
  if [[ "$1" == '--' ]]; then shift; fi

}

main "$@"