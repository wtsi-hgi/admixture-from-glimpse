process GET_POP_FILE {
    label 'process_low'

    input:
    tuple val(meta), path (fam), val(pop_column)
    val(sample_column)
    path(info_file)

    output:
    tuple val(meta), val(pop_column), path('*.pop'), emit: pop

    script:
    def input = "${fam.getBaseName()}"
    """
    echo "${sample_column}" > columns_to_select.txt
    echo "${pop_column}" >> columns_to_select.txt
    get_pop_file.py $input columns_to_select.txt $info_file

    """

}