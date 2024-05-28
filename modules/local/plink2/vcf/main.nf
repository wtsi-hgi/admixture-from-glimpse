process PLINK2_VCF {
    tag "$meta.id"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/plink2:2.00a2.3--h712d239_1' :
        'biocontainers/plink2:2.00a2.3--h712d239_1' }"

    input:
    tuple val(meta), path(vcf), path(index)

    output:
    tuple val(meta), path("*.bim")  , emit: bim, optional: true
    tuple val(meta), path("*.bed")  , emit: bed, optional: true
    tuple val(meta), path("*.fam")  , emit: fam, optional: true
    tuple val(meta), path("*.pgen") , emit: pgen, optional: true
    tuple val(meta), path("*.psam") , emit: psam, optional: true
    tuple val(meta), path("*.pvar") , emit: pvar, optional: true
    path "versions.yml"             , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script: 
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    plink2 \\
        --vcf $vcf \\
        $args \\
        --threads $task.cpus \\
        --out ${prefix}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        plink2: \$(plink2 --version 2>&1 | sed 's/^PLINK v//; s/ 64.*\$//' )
    END_VERSIONS
    """

}   