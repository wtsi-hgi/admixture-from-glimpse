include { BCFTOOLS_VIEW } from '../modules/nf-core/bcftools/view/main.nf'
include { BCFTOOLS_INDEX as INDEX_FILTER } from '../modules/nf-core/bcftools/index/main.nf'
include { BCFTOOLS_ISEC } from '../modules/nf-core/bcftools/isec/main.nf'
include { BCFTOOLS_MERGE_FROM_ISEC } from '../modules/local/bcftools/merge_from_isec/main.nf'
include { BCFTOOLS_INDEX as INDEX_MERGE } from '../modules/nf-core/bcftools/index/main.nf'
include { PLINK2_VCF } from '../modules/local/plink2/vcf/main.nf'
include { PLINK2_FILTER as PLINK2_MAF_FILTER } from '../modules/local/plink2/filter/main.nf'
include { PLINK2_FILTER as PLINK2_VAR_FILTER } from '../modules/local/plink2/filter/main.nf'
include { PLINK2_FILTER as PLINK2_SAMPLE_FILTER } from '../modules/local/plink2/filter/main.nf'
include { PLINK2_HET } from '../modules/local/plink2/het/main.nf'
include { IDENTIFY_HET_OUTLIERS } from '../modules/local/identify_het_outliers/main.nf'
include { PLINK2_REMOVE } from '../modules/local/plink2/remove/main.nf'
include { PLINK2_FILTER as PLINK2_HWE_FILTER } from '../modules/local/plink2/filter/main.nf'
include { PLINK2_INDEP_PAIRWISE } from '../modules/local/plink2/indep_pairwise/main.nf'
include { PLINK2_EXTRACT } from '../modules/local/plink2/extract/main.nf'
include { PLINK_GENOME } from '../modules/local/plink/genome/main.nf'
include { FIND_RELATED_SAMPLES } from '../modules/local/find_related_samples/main.nf'
include { PLINK2_REMOVE as PLINK2_REMOVE_RELATED } from '../modules/local/plink2/remove/main.nf'

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


    filter_input_ch1 = PLINK2_VCF.out.bed.join(PLINK2_VCF.out.bim).join(PLINK2_VCF.out.fam).map{
        meta, bed, bim, fam -> [[id:'maf_filter', prefix_in:'plink_from_vcf', prefix_out:'plink_maf_filtered'], bed, bim, fam]
    }
    PLINK2_MAF_FILTER(filter_input_ch1)
    
    filter_input_ch2 = PLINK2_MAF_FILTER.out.bed.join(PLINK2_MAF_FILTER.out.bim).join(PLINK2_MAF_FILTER.out.fam).map{
        meta, bed, bim, fam -> [[id:'var_filter', prefix_in:'plink_maf_filtered', prefix_out:'plink_var_filtered'], bed, bim, fam]
    }
    PLINK2_VAR_FILTER(filter_input_ch2)

    filter_input_ch3 = PLINK2_VAR_FILTER.out.bed.join(PLINK2_VAR_FILTER.out.bim).join(PLINK2_VAR_FILTER.out.fam).map{
        meta, bed, bim, fam -> [[id:'sample_filter', prefix_in:'plink_var_filtered', prefix_out:'plink_sample_filtered'], bed, bim, fam]
    }
    PLINK2_SAMPLE_FILTER(filter_input_ch3)

    het_input_ch = PLINK2_SAMPLE_FILTER.out.bed.join(PLINK2_SAMPLE_FILTER.out.bim).join(PLINK2_SAMPLE_FILTER.out.fam).map{
        meta, bed, bim, fam -> [[id:'inbreeding', prefix_in:'plink_sample_filtered', prefix_out:'plink_het'], bed, bim, fam]
    }
    PLINK2_HET(het_input_ch)

    IDENTIFY_HET_OUTLIERS(PLINK2_HET.out.het)

    remove_input_ch = het_input_ch.map{ meta, bed, bim, fam -> [[id:'remove_samples', prefix_in:'plink_sample_filtered', prefix_out:'het_outliers_removed'], bed, bim, fam]}
    PLINK2_REMOVE(remove_input_ch, IDENTIFY_HET_OUTLIERS.out.samples_to_exclude)

    plink_hwe_input_ch = PLINK2_REMOVE.out.bed.join(PLINK2_REMOVE.out.bim).join(PLINK2_REMOVE.out.fam).map{
        meta, bed, bim, fam -> [[id:'hwe_filter', prefix_in:'het_outliers_removed', prefix_out:'plink_hwe_filter'], bed, bim, fam]
    }

  
    PLINK2_HWE_FILTER(plink_hwe_input_ch)
   // PLINK2_HWE_FILTER.out.bed.view()

    plink_prune_input_ch = PLINK2_HWE_FILTER.out.bed.join(PLINK2_HWE_FILTER.out.bim).join(PLINK2_HWE_FILTER.out.fam).map{
        meta, bed, bim, fam -> [[id:'ld_prune', prefix_in:'plink_hwe_filter', prefix_out:'plink_ld_prune'], bed, bim, fam]
    }

    PLINK2_INDEP_PAIRWISE(plink_prune_input_ch, params.window_size, params.step, params.r_squared)
    //PLINK2_INDEP_PAIRWISE.out.prune_in.view()

    extract_input_ch = plink_prune_input_ch.join(PLINK2_INDEP_PAIRWISE.out.prune_in).map{ 
        meta, bed, bim, fam, vars -> [ [id:'ld_prune_extract', prefix_in:'plink_hwe_filter', prefix_out:'plink_ld_pruned'], bed, bim, fam, vars]
        }    
    PLINK2_EXTRACT(extract_input_ch)
    //PLINK2_EXTRACT.out.bed.view()

    plink_genome_input_ch = PLINK2_EXTRACT.out.bed.join(PLINK2_EXTRACT.out.bim).join(PLINK2_EXTRACT.out.fam).map{
        meta, bed, bim, fam -> [[id:'ibd', prefix_in:'plink_ld_pruned', prefix_out:'plink_ld_pruned'], bed, bim, fam]
    }

    PLINK_GENOME(plink_genome_input_ch)

    FIND_RELATED_SAMPLES(PLINK_GENOME.out.genome)
    //FIND_RELATED_SAMPLES.out.related.view()

    remove_related_input_ch = plink_genome_input_ch.map{
        meta, bed, bim, fam -> [[id:'rm_related', prefix_in:'plink_ld_pruned', prefix_out:'plink_remove_related'], bed, bim, fam]
    }
    
    PLINK2_REMOVE_RELATED(remove_related_input_ch, FIND_RELATED_SAMPLES.out.related)
    PLINK2_REMOVE_RELATED.out.bed.view()

}