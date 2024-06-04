process IDENTIFY_HET_OUTLIERS {
    label 'process_low'

    input:
    tuple val(meta), path(infile)

    output:
    tuple val(meta), path('samples_to_exclude.txt'), emit: samples_to_exclude

    script:
    """
    identify_meanHet_outliers.py --infile $infile --outfile samples_to_exclude.txt
    """

}