process PLINK2_HET {
    tag "$meta.id"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/plink2:2.00a5.10--h4ac6f70_0' :
        'biocontainers/plink2:2.00a5.10--h4ac6f70_0' }"

input:
    tuple val(meta), path(bed), path(bim), path(fam)

output:
    tuple val(meta), path("*.het")  , emit: het
    path "versions.yml"             , emit: versions

script: 
    def args = task.ext.args ?: ''
    """
    plink2 \\
        --bfile ${meta.prefix_in} \\
        $args \\
        --threads $task.cpus \\
        --het \\
        --out ${meta.prefix_out}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        plink2: \$(plink2 --version 2>&1 | sed 's/^PLINK v//; s/ 64.*\$//' )
    END_VERSIONS
    """

}