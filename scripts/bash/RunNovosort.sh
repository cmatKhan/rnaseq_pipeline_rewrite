#!/usr/bin/env bash

# TODO: FIND BETTER WAY OF DOING DOCSTRING/HELP
#  wrapper for novosort
#  usage: 
#  author: chase mateusiak chase.mateusiak@gmail.com

#  input:
#      -h --help should display this docstring
#      -b --bam_file path to bam file
#      -o --output filename NO PERIODS NO FILE EXTENSIONS
#      -t --num_threads number of threads to use
  
#  variable name definitions:
#      fastq_simple_name is the fastq filename stripped of any path and with the file extensions removed

#   output: 1> ${output_file_name}_sorted.bam
#           2> ${output_file_name}_novosort.log

# utils.sh needs to be in the same directory as this script
source ./utils.sh

main(){
  # main method, called at bottom of script after all functions read in

  # parse cmd line input
  parseArgs "$@"
  # verify cmd line input
  checkInput
  # check that necessary software is available
  checkPath novoalign "RunNovosortError: novosort not found in PATH"

  novosort ${bam_file} --threads ${num_threads} --markDuplicates -o ${output_file_name}_sorted.bam 2> ${output_file_name}_novosort.log
}

checkInput(){
  # check input, raise errors
  # TODO: should this go to 2 or 1?
  if [[ ! -e $bam_file ]]; then
      echo "RunNovosortInputError: bam_file does not exist"
      exit 1
  fi
  if [[ -z $output_file_name ]]; then
      echo "RunNovosortInputError: output_file_name file does not exist"
      exit 1
  fi
  if [[ -z $num_threads  && $num_threads -lt 1 ]]; then
      echo "RunNovalignInputError: num_cpus not specified"
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
    -b | --bam_file )
      shift; bam_file=$1
      ;;
    -o | --output_file_name )
      shift; output_file_name=$1
      ;;
    -t | --num_threads )
      shift; num_threads=$1
      ;;
  esac; shift; done
  if [[ "$1" == '--' ]]; then shift; fi

}

main "$@"