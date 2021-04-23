


// split columns/rows of fastq_file_list for processing
Channel
    .fromPath(params.fastq_file_list)
    .splitCsv(header:true)
    .map{row-> tuple(row.runDirectory, file(row.fastqFileName), row.organism, row.strandedness, row.fastqFileNumber) }
    .set { fastq_filelist }

index_map = [ "KN99": file(params.KN99_novoalign_index), "S288C_R64": file(params.S288C_R64_novoalign_index)]

genome_fasta_map = ["KN99": file(params.KN99_genome), "S288C_R64": file(params.S288C_R64_genome)]

num_cpus = 8

memory_request = "20G"

counts_url = "http://13.59.167.2/api/Counts/"
qc_url = "http://13.59.167.2/api/QualityAssess/"

post = false

scratch_sequence = file(params.scratch_sequence)

process fastQC {

    executor "slurm"
    memory memory_request
    module "fastqc/0.11.7-java-11"
    publishDir "$params.align_count_results/$run_directory/fastqc", mode:"copy", overwite: true, pattern: "*_fastqc.zip"

    input:
        tuple val(run_directory), file(fastq_file), val(organism), val(strandedness), val(fastq_file_number) from fastq_filelist
    output:
        file("${fastq_simple_name}_fastqc.zip")
    script:
        fastq_simple_name = fastq_file.getSimpleName()
        """
        /home/chasem/rnaseq_pipeline_rewrite/scripts/bash/RunFastQC.sh -f $fastq_file
        """
}

process Novoalign {

    executor "slurm"
    cpus num_cpus
    memory memory_request
    module "novoalign/3.09.01"
    publishDir "$params.align_count_results/$run_directory/logs", mode:"copy", overwite: true, pattern: "*.log"

    input:
        tuple val(run_directory), file(fastq_file), val(organism), val(strandedness), val(fastq_file_number) from fastq_filelist
    output:
        tuple val(fastq_file_number), val(run_directory), val(fastq_simple_name), val(organism), val(strandedness), file("${fastq_simple_name}.bam") into bam_align_ch
        tuple val(fastq_file_number), val(fastq_simple_name), file("${fastq_simple_name}_novoalign.log") into novoalign_log_ch

    script:
        fastq_simple_name = fastq_file.getSimpleName()
        index = index_map[organism]
        """
        /home/chasem/rnaseq_pipeline_rewrite/scripts/bash/RunNovoalign.sh -i $index -f $fastq_file -o $fastq_simple_name -c $num_cpus
        """
}

// split into two for two separate processes
bam_align_ch.into { bam_htseq_ch; bam_novosort_ch }

process HtseqCount {

    executor "slurm"
    memory "10G"
    // module "miniconda"
    // conda "htseq"
    module "htseq/0.9.1"
    publishDir "$params.align_count_results/$run_directory/logs", mode:"copy", overwite: true, pattern: "*.log"
    publishDir "$params.align_count_results/$run_directory/count", mode:"copy", overwite: true, pattern: "*_read_count.tsv"
    publishDir "$params.align_count_results/$run_directory/align", mode:"copy", overwite: true, pattern: "*.sam"


    input:
        tuple val(fastq_file_number), val(run_directory), val(fastq_simple_name), val(organism), val(strandedness), file(bam) from bam_htseq_ch
    output:
        tuple val(fastq_file_number), val(run_directory), val(fastq_simple_name), file("${fastq_simple_name}_read_count.tsv") into htseq_count_ch
        file("${fastq_simple_name}_htseq.log") into htseq_log_ch
        tuple val(run_directory), val(organism), val(strandedness) into pipeline_info_ch

// #   output: -o ${output_file_name}_htseq_annote.sam (this is a file with the same number of lines as the input bam and gives a flag eg XF:CNAG_12345 for the feature count to which the read contributed)
// #           1> ${output_file_name}_read_count.tsv
// #           2> ${output_file_name}_htseq.log

    script:
        if (organism == 'S288C_R64')
        """
        /home/chasem/rnaseq_pipeline_rewrite/scripts/bash/RunHtseqCounts.sh -f $bam -a $params.S288C_R64_annotation_file -t exon -i gene -s $strandedness -o $fastq_simple_name
        """
        else if (organism == 'KN99' && strandedness == 'reverse')
        """
        /home/chasem/rnaseq_pipeline_rewrite/scripts/bash/RunHtseqCounts.sh -f $bam -a $params.KN99_annotation_file -t exon -i gene -s $strandedness -o $fastq_simple_name
        """
        else if (organism == 'KN99' && strandedness == 'no')
        """
        /home/chasem/rnaseq_pipeline_rewrite/scripts/bash/RunHtseqCounts.sh -f $bam -a $params.KN99_annotation_file_no_strand -t exon -i gene -s $strandedness -o $fastq_simple_name
        """
}

// process postHtseqCountsToDatabase {

//     executor "local"
//     beforeScript "ml rnaseq_pipeline"
//     publishDir "$params.align_count_results/$run_directory/count", mode:"copy", overwite: true, pattern: "*_counts.csv"
//     publishDir "$params.align_count_results/$run_directory/log", mode:"copy", overwite: true, pattern: "*_htseq_qc.csv"

//     input:
//         tuple val(fastq_file_number), val(run_directory), val(fastq_simple_name), file(read_count_tsv) from htseq_count_ch
//     output:
//         tuple file("${fastq_simple_name}_counts.csv"), file("${fastq_simple_name}_htseq_qc.csv") into parsed_counts_ch
        

//     // # output: ${sample_name}_counts.csv, ${sample_name}_htseq_qc.csv
//     // # database_interaction: post to url

//     script:
//     if (post)
//     """
//         /home/chasem/rnaseq_pipeline_rewrite/scripts/python/PostCountsToDatabase.py -c $read_count_tsv -n $fastq_simple_name -i $fastq_file_number -cu $counts_url -qu $qc_url
//     """
//     else
//     """
//         /home/chasem/rnaseq_pipeline_rewrite/scripts/python/PostCountsToDatabase.py -c $read_count_tsv -n $fastq_simple_name -i $fastq_file_number -cu $counts_url -qu $qc_url --no-post
//     """
// }

process Novosort {

    executor "slurm"
    cpus 8
    memory "20G"
    module "novoalign/3.09.01"
    publishDir "$params.align_count_results/$run_directory/align", mode:"copy", overwite: true, pattern: "*.bam"


    input:
        tuple val(fastq_file_number), val(run_directory), val(fastq_simple_name), val(organism), val(strandedness), file(bam) from bam_novosort_ch
    output:
        tuple val(run_directory), file("${fastq_simple_name}_sorted.bam") into sorted_bam_ch
        file("${fastq_simple_name}_novosort.log") into novosort_ch

    
// #   output: 1> ${output_file_name}_sorted.bam
// #           2> ${output_file_name}_novosort.log

    script:
        """
        /home/chasem/rnaseq_pipeline_rewrite/scripts/bash/RunNovosort.sh -b $bam -o $fastq_simple_name -t 8
        """
}

process IndexFinalBam {
    executor "slurm"
    memory "10G"
    module "rnaseq_pipeline"
    // conda "samtools"
    publishDir "$params.align_count_results/$run_directory/align", mode:"copy", overwite: true, pattern: "*.bai"

    input:
        tuple val(run_directory), file(sorted_annoted_bam) from sorted_bam_ch
    output:
        file('*.bai') into index_ch

    script:
    """
        samtools index $sorted_annoted_bam
    """
}


