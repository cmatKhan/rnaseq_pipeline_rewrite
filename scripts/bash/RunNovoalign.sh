#!/usr/bin/env bash

# TODO: FIND BETTER WAY OF DOING DOCSTRING/HELP
#  wrapper for novoalign accepting a subset of the novoalign settings
#  usage: RunNovoalign.sh -i /path/to/novoalign_index.idx -f /path/to/reads.fastq.gz -c num_cpus
#  author: chase mateusiak chase.mateusiak@gmail.com

#  input:
#      -h --help should display this docstring
#      -i --index is the path to the novoalign index file (see novoalign documentation)
#      -f --fastq is the path to the fastq file. The extension must be .fq.gz or .fastq.gz
#      -o --output filename NO PERIODS NO FILE EXTENSIONS
#      -c --num_cpus is the number of cpus

#   output: 1> ${output_file_name}.bam
#           2> ${output_file_name}_novoalign.log

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
  checkPath novoalign "RunNovalignError: novoalign not found in PATH"

  novoalign \
    -r All 100 \
    -c ${num_cpus} \
    -o SAM \
    -d ${index_path} \
    -f ${fastq_path} \
    1> ${output_file_name}.bam \
    2> ${output_file_name}_novoalign.log 
}

checkInput(){
  # check input, raise errors
  # TODO: should this go to 2 or 1?
  if [[ ! -e $index_path ]]; then
      echo "RunNovoalignInputError: index ${index_path} does not exist"
      exit 1
  fi
  if [[ ! -e $fastq_path ]]; then
      echo "RunNovoalignInputError: fastq ${fastq_path} file does not exist"
      exit 1
  fi
  if [[ !(${fastq_path#*.} == fq.gz || ${fastq_path#*.} == fastq.gz)  ]]; then
      echo "RunNovoalignInputError: fastq path does not end with .fq.gz or .fastq.gz. One of the two is the required extension for fastq files."
      exit 1
  fi
  # TODO: add error checking -- should not include any periods
  if [[ -z $output_file_name ]]; then
      echo "RunNovalignInputError: output_file_name not specified"
      exit 1
  fi 
  if [[ -z $num_cpus  && $num_cpus -lt 1 ]]; then
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
      head -${last_line_docstring} $0
      exit
      ;;
    -i | --index )
      shift; index_path=$1
      ;;
    -f | --fastq )
      shift; fastq_path=$1
      ;;
    -o | --output_file_name )
      shift; output_file_name=$1
      ;;
    -c | --num_cpus )
      shift; num_cpus=$1
      ;;
  esac; shift; done
  if [[ "$1" == '--' ]]; then shift; fi

}

main "$@"