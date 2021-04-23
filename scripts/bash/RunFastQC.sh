#!/usr/bin/env bash

# TODO: FIND BETTER WAY OF DOING DOCSTRING/HELP
#  wrapper for fastqc
#  usage: RunFastQC.sh -f /path/to/fastq.gz
#  author: chase mateusiak chase.mateusiak@gmail.com

#  input:
#      -h --help should display this docstring
#      -f --fastq is the path to the fastq file. The extension must be .fq.gz or .fastq.gz

#   output: to the same directory as input fastq, two items -- a .html summary and a .zip


last_line_docstring=16

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
  checkPath fastqc "RunFastQCError: fastqc not found in PATH"

  novoalign ${fastq_path}
}

checkInput(){
  # check input, raise errors
  # TODO: should this go to 2 or 1?
  if [[ ! -e $fastq_path ]]; then
      echo "RunFastQCInputError: fastq ${fastq_path} file does not exist"
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
    -f | --fastq )
      shift; fastq_path=$1
      ;;
  esac; shift; done
  if [[ "$1" == '--' ]]; then shift; fi

}

main "$@"