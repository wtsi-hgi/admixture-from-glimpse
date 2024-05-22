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

    //BCFTOOLS_VIEW.out.vcf.view()
    // INDEX_FILTER.out.csi.view()
    // isec_meta = [id: 'isec']

    pops_vcf_ch = channel.fromPath(params.pops_vcf).map{ vcf -> [[id: 'glimpse_filter_info'], vcf]}
    //pops_index_ch = channel.fromPath(params.pops_vcf_index)
    pops_index_ch = channel.fromPath(params.pops_vcf_index).map{ index -> [[id: 'glimpse_filter_info'], index]}

    // vcfs_ch = BCFTOOLS_VIEW.out.vcf.combine(pops_vcf_ch, by: 0)
    // indexes_ch = INDEX_FILTER.out.csi.join(pops_index_ch, by: 0)

    // vcfs_ch.view()
    // indexes_ch.view()
    filtered_output_ch = BCFTOOLS_VIEW.out.vcf.groupTuple(by: 0)
    index_filtered_output_ch = INDEX_FILTER.out.csi.groupTuple(by: 0)
    //filtered_output_ch.view()

    pops_vcf_ch2 = pops_vcf_ch.groupTuple(by: 0)
    pops_index_ch2 = pops_index_ch.groupTuple(by: 0)
    //pops_index_ch2.view()

    vcfs_input = filtered_output_ch.combine(pops_vcf_ch2).map{ meta1, vcf1, meta2, vcf2 -> [vcf1, vcf2]}.flatten().collect().map{ vcfs -> [[id: 'isec'], vcfs]}
    indexes_input = index_filtered_output_ch.combine(pops_index_ch).map{ meta1, index1, meta2, index2 -> [index1, index2]}.flatten().collect().map{ indexes -> [[id: 'isec'], indexes]}
    
    
    isec_input = vcfs_input.join(indexes_input, by: 0)
   
    // isec_input_ch = vcfs_input.join(indexes_input).map{ vcfs, indexes -> [[id: 'isec'], vcfs, indexes]}
    // isec_input_ch.view()
    
    // testdata_input = filtered_output_ch.combine(index_filtered_output_ch).map{ meta1, vcf, meta2, index -> [meta1, vcf, index]}
    // pops_data_input = pops_vcf_ch2.combine(pops_index_ch2).map{ meta1, vcf, meta2, index -> [meta1, vcf, index]}
    // isec_input = testdata_input.combine(pops_data_input).map{
    //     meta1, vcf1, index1, meta2, vcf2, index2 -> 
    //     [meta1, [vcf1,vcf2], [index1, index2]]
    // }
    // isec_input.view()
    //pops_data_input.view()
    // isec_ch = vcfs_ch.join(indexes_ch, by: 0)
    // isec_ch.view()
    // filtered_ch = BCFTOOLS_VIEW.out.vcf.groupTuple(by: 0)
    // filtered_index_ch = INDEX_FILTER.out.csi.groupTuple(by: 0)
    // filtered_ch.view()
    // filtered_index_ch.view()

    // pops_vcf_ch.view()
    // pops_ch = pops_vcf_ch.combine(pops_index_ch)
    // pops_ch = pops_ch.map{ vcf, index -> [[id: 'glimpse_filter_info_'], vcf,index]}
    // pops_ch.view()
    // test_filtered_ch = BCFTOOLS_VIEW.out.vcf.join(INDEX_FILTER.out.csi, by: 0)
    // isec_ch = test_filtered_ch.join(pops_ch, by: 0)
    // isec_ch.view()
    // vcf_ch = BCFTOOLS_VIEW.out.vcf.join(pops_vcf_ch)
    // //index_ch = INDEX_FILTER.out.csi.combine(pops_index_ch)
    // vcf_ch.view()
    //index_ch.view()
    // isec_ch = vcf_ch.join(index_ch, by: 0)
    // isec_ch.view()
    

    BCFTOOLS_ISEC( isec_input )
    BCFTOOLS_ISEC.out.results.view()
}