process BCFTOOLS_MERGE_FROM_ISEC {
    tag "$meta.id"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/bcftools:1.18--h8b25389_0':
        'biocontainers/bcftools:1.18--h8b25389_0' }"

    input:
        tuple val(meta), path(isec_dir)

    output:
        tuple val(meta), path("*.vcf.gz"), path("*.vcf.gz.csi"), emit: merged_variants

    script:
        """
        bcftools \\
            index \\
            -f \\
            --threads $task.cpus \\
            ${meta.id}/0002.vcf.gz

        bcftools \\
            index \\
            -f \\
            --threads $task.cpus \\
            ${meta.id}/0003.vcf.gz

        bcftools \\
            merge \\
            --threads $task.cpus \\
            -Oz \\
            -o ${meta.id}_merged.vcf.gz \\
            ${meta.id}/0002.vcf.gz ${meta.id}/0003.vcf.gz

         bcftools \\
            index \\
            -f \\
            --threads $task.cpus \\
            ${meta.id}_merged.vcf.gz

        """
}