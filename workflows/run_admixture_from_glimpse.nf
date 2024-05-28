include { BCFTOOLS_VIEW } from '../modules/nf-core/bcftools/view/main.nf'
include { BCFTOOLS_INDEX as INDEX_FILTER } from '../modules/nf-core/bcftools/index/main.nf'
include { BCFTOOLS_ISEC } from '../modules/nf-core/bcftools/isec/main.nf'
include { BCFTOOLS_MERGE_FROM_ISEC } from '../modules/local/bcftools/merge_from_isec/main.nf'
include { BCFTOOLS_INDEX as INDEX_MERGE } from '../modules/nf-core/bcftools/index/main.nf'
include { PLINK2_VCF } from '../modules/local/plink2/vcf/main.nf'

workflow RUN_ADMIXTURE_FROM_GLIMPSE {
    // step 1 - filter test data by minimum info score
    vcf_ch = channel.fromPath(params.test_vcf)
    index_ch = channel.fromPath(params.test_vcf_index)
    bcftools_view_input_ch = vcf_ch.combine(index_ch).map{
                                                            vcf, index -> 
                                                            [[id: 'glimpse_filter_info'], vcf, index]
                                                            }

    BCFTOOLS_VIEW ( bcftools_view_input_ch, [], [], [] )

    INDEX_FILTER ( BCFTOOLS_VIEW.out.vcf )

    filtered_output_ch = BCFTOOLS_VIEW.out.vcf
    index_filtered_output_ch = INDEX_FILTER.out.csi
    pops_vcf_ch = channel.fromPath(params.pops_vcf)
    pops_index_ch = channel.fromPath(params.pops_vcf_index)

    vcf_ch = filtered_output_ch.merge(pops_vcf_ch).map{meta, a, b -> [meta, [a, b]]}
    index_ch = index_filtered_output_ch.merge(pops_index_ch).map{meta, a, b -> [meta, [a, b]]}

    isec_input_ch = vcf_ch.join(index_ch)

    BCFTOOLS_ISEC( isec_input_ch )
 
    BCFTOOLS_MERGE_FROM_ISEC(BCFTOOLS_ISEC.out.results)


    plink_vcf_input_ch = BCFTOOLS_MERGE_FROM_ISEC.out.merged_variants.map{ meta, vcf, index -> [[id: 'plink_from_vcf'], vcf, index]}
    PLINK2_VCF(plink_vcf_input_ch)
    PLINK2_VCF.out.bim.view()
    
}