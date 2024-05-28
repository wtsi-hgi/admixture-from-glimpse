process PLINK2_FILTER {
    tag "$meta.id"
    label 'process_low'

input:
    tuple val(meta), path(bed), path(bim), path(fam)

output:
    tuple val(meta), path("*.bed"), emit: bed
    tuple val(meta), path("*.bim"), emit: bim
    tuple val(meta), path("*.fam"), emit: fam   

}