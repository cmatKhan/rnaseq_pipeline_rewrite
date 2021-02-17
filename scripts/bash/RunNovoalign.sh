#!/usr/bin/env bash

# TODO: FIND BETTER WAY OF DOING DOCSTRING/HELP
#  wrapper for novoalign accepting a subset of the novoalign settings
#  usage RunNovoalign -i /path/to/novoalign_index.idx -f /path/to/reads.fastq.gz -c num_cpus
#  author: chase mateusiak chase.mateusiak@gmail.com

#  input:
#      -i --index is the path to the novoalign index file (see novoalign documentation)
#      -f --fastq is the path to the fastq file. The extension must be .fq.gz or .fastq.gz
#      -c --num_cpus is the number of cpus
  
#  variable name definitions:
#      fastq_simple_name is the fastq filename stripped of any path and with the file extensions removed

#   output: 1> fastq_simple_name.sam
#           2> fastq_simple_name_novoalign.log

main(){
  # main method, called at bottom of script after all functions read in

  parseArgs "$@"
  checkInput

  # check if novoalign is available on the system
  # cite: https://stackoverflow.com/a/677212/9708266
  if ! command -v novoalign &> /dev/null
  then
    echo "RunNovalignError: novoalign not found in path"
    exit 1
  fi
  
  # TODO: CLEAN THIS UP (NOTE: checkInput does check that the file end in one of these two extensions)
  local fastq_basename=$(basename $fastq_path)
  local fastq_simple_name=${fastq_basename%.gz}
  local fastq_simple_name=${fastq_basename%.fq}
  local fastq_simple_name=${fastq_basename%.fastq}

  novoalign -r All \\
            -c ${num_cpus}\\
            -o SAM \\
            -d ${index_path} \\
            -f ${fastq_path} \\
              1> ${fastq_simple_name}.sam \\
              2> ${fastq_simple_name}_novoalign.log 
}

checkInput(){
  # check input, raise errors
  # TODO: should this go to 2 or 1?
  if [[ ! -e $index_path ]]; then
      echo "RunNovoalignInputError: index does not exist"
      exit 1
  fi
  if [[ ! -e $fastq_path ]]; then
      echo "RunNovoalignInputError: fastq file does not exist"
      exit 1
  fi
  if [[ !(${fastq_path#*.} == fq.gz || ${fastq_path#*.} == fastq.gz)  ]]; then
      echo "RunNovoalignInputError: fastq path does not end with .fq.gz or .fastq.gz. One of the two is the required extension for fastq files."
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
      $(head -16 $0)
      exit
      ;;
    -i | --index )
      shift; index_path=$1
      ;;
    -f | --fastq )
      shift; fastq_path=$1
      ;;
    -c | --num_cpus )
      num_cpus=1
      ;;
  esac; shift; done
  if [[ "$1" == '--' ]]; then shift; fi

}

main "$@"