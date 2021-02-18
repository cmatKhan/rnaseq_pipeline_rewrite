process postHtseqCountsToDatabase {

    executor "local"
    beforeScript "ml rnaseq_pipeline"

    input:
        tuple val(fastq_file_number), val(run_directory), val(fastq_simple_name), file(read_count_tsv) from htseq_count_ch

    # output: ${sample_name}_counts.csv, ${sample_name}_htseq_qc.csv
    # database_interaction: post to url

    script:
    """
        if [[ post is set to true in params ]]l; then
            PostCountsToDatabase.py -c /path/to/count/file -n sample_name -i fastq_file_number -u url
        else
            PostCountsToDatabase.py -c /path/to/count/file -n sample_name -i fastq_file_number -u url --no-post
        fi
    """



}