process GET_FILTER_STATS {
    label 'process_low'

    input:
    tuple val(meta), path(fam), path(bim), path(ref_samples)

    output:
    tuple val(meta), path('filter_stats.*.txt'), emit: filter_stats

    script:
    def step = task.ext.prefix ?: "${meta.id}"
    """
    all_samples=\$(wc -l $fam | cut -f1 -d " ")
    variants=\$(wc -l $bim | cut -f1 -d " ")
    samples=\$(cut -f1 $fam | grep -F -v -x -f $ref_samples | wc -l)
    echo -e "${step}\t\$all_samples (\$samples)\t\$variants" > filter_stats.${step}.txt
    """
}

process GET_VCF_STATS {
    label 'process_low'

    input:
    tuple val(meta), path(stats)

    output:
    tuple val(meta), path('filter_stats.*.txt'), emit: filter_stats

    script:
    def step = task.ext.prefix ?: "${meta.id}"
    """
    samples=\$(grep "number of samples:" $stats | cut -f2 -d ":" | tr -d ' ')
    variants=\$(grep "number of records:" $stats | cut -f2 -d ":" | tr -d ' ')
    echo -e "${step}\t\$samples\t\$variants" > filter_stats.${step}.txt
    """
}

process GET_SUMMARY {
    label 'process_low'
  
    publishDir "${params.publishdir}", mode: 'copy', pattern: "filter_summary.txt"
  
    input:
    path(stat_txt_ch)

    output:
    path("filter_summary.txt"),  emit: filter_summary_file

    script:
    """
    # Concatenate all .txt files
    cat ${stat_txt_ch} | sort -t_ -k1,1n > filter_summary.txt
    """
}
