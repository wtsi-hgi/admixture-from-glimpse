process ANNOTATE_Q_FILE {
    label 'process_low'

    publishDir "${params.publishdir}", mode: 'copy', pattern: "*Q.with_sample_and_pop"

    input:
    tuple val(meta), path(q_file), path(fam), path(pops_file)

    output:
    tuple val(meta), path("*Q.with_sample_and_pop"), emit: annotated_q_file

    script:
    """
    cut -f1 -d' ' ${fam} > sample_list.txt

    paste sample_list.txt ${q_file} > ${meta.id}.Q.with_sample

    annotate_q_file_with_pop.py --q_file ${meta.id}.Q.with_sample --pops_file ${pops_file} --outfile ${meta.id}.Q.with_sample_and_pop
    """

}