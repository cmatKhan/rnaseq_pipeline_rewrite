// split columns/rows of fastq_file_list for processing
Channel
    .fromPath(params.fastq_file_list)
    .splitCsv(header:true)
    .map{row-> tuple(row.runDirectory, file(row.fastqFileName), row.organism, row.strandedness, row.fastqFileNumber) }
    .set { fastq_filelist }


scratch_sequence = file(params.scratch_sequence)