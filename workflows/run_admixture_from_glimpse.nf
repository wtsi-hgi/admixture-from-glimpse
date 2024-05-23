include { BCFTOOLS_VIEW } from '../modules/nf-core/bcftools/view/main.nf'
include { BCFTOOLS_INDEX as INDEX_FILTER } from '../modules/nf-core/bcftools/index/main.nf'
include { BCFTOOLS_ISEC } from '../modules/nf-core/bcftools/isec/main.nf'
include { BCFTOOLS_MERGE } from '../modules/nf-core/bcftools/merge/main.nf'

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


    // pops_vcf_ch = channel.fromPath(params.pops_vcf).map{ vcf -> [[id: 'glimpse_filter_info'], vcf]}
    // pops_index_ch = channel.fromPath(params.pops_vcf_index).map{ index -> [[id: 'glimpse_filter_info'], index]}

    // filtered_output_ch = BCFTOOLS_VIEW.out.vcf.groupTuple(by: 0)
    // index_filtered_output_ch = INDEX_FILTER.out.csi.groupTuple(by: 0)

    // pops_vcf_ch2 = pops_vcf_ch.groupTuple(by: 0)
    // pops_index_ch2 = pops_index_ch.groupTuple(by: 0)

    // vcfs_input = filtered_output_ch.combine(pops_vcf_ch2).map{ meta1, vcf1, meta2, vcf2 -> [vcf1, vcf2]}.flatten().collect().map{ vcfs -> [[id: 'isec'], vcfs]}
    // indexes_input = index_filtered_output_ch.combine(pops_index_ch).map{ meta1, index1, meta2, index2 -> [index1, index2]}.flatten().collect().map{ indexes -> [[id: 'isec'], indexes]}
    // isec_input = vcfs_input.join(indexes_input, by: 0)

    // BCFTOOLS_ISEC( isec_input )
    // BCFTOOLS_ISEC.out.results.view()

    filtered_output_ch = BCFTOOLS_VIEW.out.vcf
    index_filtered_output_ch = INDEX_FILTER.out.csi
    pops_vcf_ch = channel.fromPath(params.pops_vcf)
    pops_index_ch = channel.fromPath(params.pops_vcf_index)

    vcf_ch = filtered_output_ch.merge(pops_vcf_ch).map{meta, a, b -> [meta, [a, b]]}
    index_ch = index_filtered_output_ch.merge(pops_index_ch).map{meta, a, b -> [meta, [a, b]]}

    isec_input_ch = vcf_ch.join(index_ch)

    BCFTOOLS_ISEC( isec_input_ch )
    BCFTOOLS_ISEC.out.results.view()
    
}