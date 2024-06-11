process PLINK2_PCA {
    tag "$meta.id"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/plink2:2.00a5.10--h4ac6f70_0' :
        'biocontainers/plink2:2.00a5.10--h4ac6f70_0' }"

input:
    tuple val(meta), path(bed), path(bim), path(fam)

output:
    tuple val(meta), path("*.eigenvec")  , emit: eigenvec
    tuple val(meta), path("*.eigenval")  , emit: eigenval
    tuple val(meta), path("*.bim")  , emit: bim, optional: true
    tuple val(meta), path("*.bed")  , emit: bed, optional: true
    tuple val(meta), path("*.fam")  , emit: fam, optional: true
    tuple val(meta), path("*.pgen") , emit: pgen, optional: true
    tuple val(meta), path("*.psam") , emit: psam, optional: true
    tuple val(meta), path("*.pvar") , emit: pvar, optional: true
    path "versions.yml"             , emit: versions

script: 
    def args = task.ext.args ?: ''
    """
    plink2 \\
        --bfile ${meta.prefix_in} \\
        $args \\
        --threads $task.cpus \\
        --pca \\
        --out ${meta.prefix_out}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        plink2: \$(plink2 --version 2>&1 | sed 's/^PLINK v//; s/ 64.*\$//' )
    END_VERSIONS
    """

}