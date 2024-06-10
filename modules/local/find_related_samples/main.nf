process FIND_RELATED_SAMPLES {
    label 'process_low'

    input:
    tuple val(meta), path(infile)

    output:
    tuple val(meta), path('related_samples.txt'), emit: related

    script:
    """
    find_related_samples.py --infile $infile --outfile related_samples.txt
    """

}