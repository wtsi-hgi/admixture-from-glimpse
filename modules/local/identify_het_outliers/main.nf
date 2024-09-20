process IDENTIFY_HET_OUTLIERS {
    label 'process_low'

    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
      'https://depot.galaxyproject.org/singularity/pandas:2.2.1':
      'biocontainers/pandas:2.2.1' }"

    input:
    tuple val(meta), path(infile)

    output:
    tuple val(meta), path('samples_to_exclude.txt'), emit: samples_to_exclude

    script:
    """
    identify_meanHet_outliers.py --infile $infile --outfile samples_to_exclude.txt
    """

}