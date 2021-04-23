#!/usr/bin/env bash

# TODO: FIND BETTER WAY OF DOING DOCSTRING/HELP
#  wrapper for samtools view to convert sam to bam
#  author: chase mateusiak chase.mateusiak@gmail.com

#  input:
#      -h --help should display this docstring
#      -s --sam_path path to sam file
#      -g --genome_fasta path to genome fasta
#      -o --output_file_name NO PERIODS NO FILE EXTENSIONS

#   output: 1> sam_simple_name.bam

last_line_docstring=12

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
  checkPath samtools "ConvertSamToBamError: samtools not found in PATH"

  samtools view -b -T $genome  $sam_path 1> ${output_file_name}.bam
}

checkInput(){
  # check input, raise errors
  # TODO: should this go to 2 or 1?
  if [[ ! -e $sam_path ]]; then
      echo "ConvertSamToBamInputError: the sam file ${sam_path} does not exist"
      exit 1
  fi
    if [[ ! -e $genome ]]; then
      echo "ConvertSamToBamInputError: the genome file ${genome} does not exist"
      exit 1
  fi
  if [[ -z $output_file_name ]]; then
      echo "ConvertSamToBamInputError: output_file_name file does not exist"
      exit 1
  fi
  if [[ !(${sam_path#*.} == sam)  ]]; then
      echo "ConvertSamToBamInputError: the sam file does not end in .sam"
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
    -s | --sam_path )
      shift; sam_path=$1
      ;;
    -g | --genome_fasta )
      shift; genome=$1
      ;;
    -o | --output_file_name )
      shift; output_file_name=$1
      ;;
  esac; shift; done
  if [[ "$1" == '--' ]]; then shift; fi

}

main "$@"