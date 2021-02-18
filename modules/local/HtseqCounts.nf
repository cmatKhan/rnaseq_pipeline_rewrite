process htseq_count {

    scratch true
    executor "slurm"
    cpus 8
    memory "20G"
    beforeScript "ml samtools htseq"
    stageInMode "copy"
    stageOutMode "move"
    publishDir "$params.align_count_results/$run_directory/logs", mode:"copy", overwite: true, pattern: "*.log"
    publishDir "$params.align_count_results/$run_directory/count", mode:"copy", overwite: true, pattern: "*_read_count.tsv"
    publishDir "$params.align_count_results/$run_directory/align", mode:"copy", overwite: true, pattern: "*_sorted_aligned_reads_with_annote.bam"


    input:
        tuple val(fastq_file_number), val(run_directory), val(fastq_simple_name), val(organism), val(strandedness), file(sorted_bam) from bam_align_ch
    output:
        tuple val(run_directory), val(fastq_simple_name), val(organism), val(strandedness), file("${fastq_simple_name}_sorted_aligned_reads_with_annote.bam") into bam_align_with_htseq_annote_ch
        tuple val(fastq_file_number), val(run_directory), val(fastq_simple_name), file("${fastq_simple_name}_read_count.tsv") into htseq_count_ch
        tuple val(run_directory), val(fastq_simple_name), file("${fastq_simple_name}_htseq.log") into htseq_log_ch
        tuple val(run_directory), val(organism), val(strandedness) into pipeline_info_ch

#   output: -o ${output_file_name}_htseq_annote.sam (this is a file with the same number of lines as the input bam and gives a flag eg XF:CNAG_12345 for the feature count to which the read contributed)
#           1> ${output_file_name}_read_count.tsv
#           2> ${output_file_name}_htseq.log

    script:
        """
        RunHtseqCounts.sh -b /path/to/SORTED/bamfile -a /path/to/annotation/file -t feature_type -i id_attribute -s strandedness -o output_file_name
        
        """
}

