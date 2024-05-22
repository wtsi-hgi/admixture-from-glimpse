nextflow.enable.dsl=2

include { RUN_ADMIXTURE_FROM_GLIMPSE } from './workflows/run_admixture_from_glimpse.nf'

workflow MAIN {
    RUN_ADMIXTURE_FROM_GLIMPSE ()
}

workflow {
    MAIN ()
}