process novoalign {

    scratch true
    executor "slurm"
    cpus 8
    memory "20G"
    beforeScript "ml novoalign samtools"
    stageInMode "copy"
    stageOutMode "move"
    publishDir "$params.align_count_results/$run_directory/logs", mode:"copy", overwite: true, pattern: "*.log"


    input:
        tuple val(run_directory), file(fastq_file), val(organism), val(strandedness), val(fastq_file_number) from fastq_filelist
    output:
        tuple val(fastq_file_number), val(run_directory), val(fastq_simple_name), val(organism), val(strandedness), file("${fastq_simple_name}_sorted_aligned_reads.bam") into bam_align_ch
        tuple val(run_directory), file("${fastq_simple_name}_novoalign.log"), file("${fastq_simple_name}_novosort.log") into novoalign_log_ch

#   output: 1> sam_simple_name.bam

    script:
            """
            ConvertSamToBam.sh -s /path/to/sam -o output_file_name
            """
}
