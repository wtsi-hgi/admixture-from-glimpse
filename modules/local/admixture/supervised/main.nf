process SUPERVISED_ADMIXTURE {
    tag "$meta.id"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/admixture:1.3.0--0':
        'biocontainers/admixture:1.3.0--0' }"

    input:
    tuple val(meta), path (bed), path(bim), path(fam), path (pop)


    output:
    tuple val(meta), path("*.Q")    , emit: ancestry_fractions
    tuple val(meta), path("*.P")    , emit: allele_frequencies
    path "versions.yml"  , emit: versions
    path ("cv_*.txt")   , emit: cross_validation

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    npop=\$(sort $pop | uniq | awk 'END {print NR-1}')

    echo \$npop
    
    admixture $bed \$npop -j$task.cpus --supervised --cv
    
    grep -h CV .command.out > cv_\${npop}.txt
    
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        admixture: \$(echo \$(admixture 2>&1) | head -n 1 | grep -o "ADMIXTURE Version [0-9.]*" | sed 's/ADMIXTURE Version //' )
    END_VERSIONS
    """
}