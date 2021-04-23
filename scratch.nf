process index {
    tag "$transcriptome.simpleName"

    input:
    path transcriptome from params.transcriptome

    output:
    path 'index' into index_ch

    script:
    """
    salmon index --threads $task.cpus -t $transcriptome -i index
    """
}


process quant {
    tag "$pair_id"

    input:
    path index from index_ch
    tuple pair_id, path(reads) from read_pairs_ch

    output:
    path pair_id into quant_ch

    script:
    """
    salmon quant --threads $task.cpus --libType=U -i $index -1 ${reads[0]} -2 ${reads[1]} -o $pair_id
    """
}

process fastqc {
    tag "FASTQC on $sample_id"
    publishDir params.outdir

    input:
    tuple sample_id, path(reads) from read_pairs2_ch

    output:
    path "fastqc_${sample_id}_logs" into fastqc_ch


    script:
    """
    mkdir fastqc_${sample_id}_logs
    fastqc -o fastqc_${sample_id}_logs -f fastq -q ${reads}
    """
}


process multiqc {
    publishDir params.outdir, mode:'copy'
    
    input:
    path 'data*/*' from quant_ch.mix(fastqc_ch).collect()
    path config from params.multiqc

    output:
    path 'multiqc_report.html'

    script:
    """
    cp $config/* .
    echo "custom_logo: \$PWD/logo.png" >> multiqc_config.yaml
    multiqc -v .
    """
}