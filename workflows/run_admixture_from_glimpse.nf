include { BCFTOOLS_VIEW } from '../modules/nf-core/bcftools/view/main.nf'
include { BCFTOOLS_INDEX as INDEX_FILTER } from '../modules/nf-core/bcftools/index/main.nf'
include { BCFTOOLS_ISEC } from '../modules/nf-core/bcftools/isec/main.nf'
include { BCFTOOLS_MERGE_FROM_ISEC } from '../modules/local/bcftools/merge_from_isec/main.nf'
include { BCFTOOLS_INDEX as INDEX_MERGE } from '../modules/nf-core/bcftools/index/main.nf'
include { PLINK2_VCF } from '../modules/local/plink2/vcf/main.nf'
include { PLINK2_FILTER as PLINK2_MAF_FILTER } from '../modules/local/plink2/filter/main.nf'
include { PLINK2_FILTER as PLINK2_VAR_FILTER } from '../modules/local/plink2/filter/main.nf'
include { PLINK2_FILTER as PLINK2_SAMPLE_FILTER } from '../modules/local/plink2/filter/main.nf'
include { PLINK2_HET } from '../modules/nf-core/plink2/het/main.nf'
include { IDENTIFY_HET_OUTLIERS } from '../modules/local/identify_het_outliers/main.nf'
include { PLINK2_REMOVE } from '../modules/nf-core/plink2/remove/main.nf'
include { PLINK2_REMOVE as PLINK2_REMOVE_SELECTED_SAMPLES } from '../modules/nf-core/plink2/remove/main.nf'
include { PLINK2_FILTER as PLINK2_HWE_FILTER } from '../modules/local/plink2/filter/main.nf'
include { PLINK2_INDEPPAIRWISE } from '../modules/nf-core/plink2/indeppairwise/main.nf'
include { PLINK2_EXTRACT } from '../modules/local/plink2/extract/main.nf'
include { PLINK_GENOME } from '../modules/local/plink/genome/main.nf'
include { FIND_RELATED_SAMPLES } from '../modules/local/find_related_samples/main.nf'
include { PLINK2_REMOVE as PLINK2_REMOVE_RELATED } from '../modules/nf-core/plink2/remove/main.nf'
include { PLINK2_PCA } from '../modules/local/plink2/pca/main.nf'
include { ADMIXTURE } from '../modules/nf-core/admixture/main.nf'
include { MERGE_TXT } from '../modules/local/merge_txt/main.nf'
include { ANNOTATE_Q_FILE } from '../modules/local/annotate_q_file/main.nf'
include { GET_POP_FILE } from '../modules/local/get_pop_file/main.nf'
include { SUPERVISED_ADMIXTURE } from '../modules/local/admixture/supervised/main.nf'
include { ANNOTATE_SUPERVISED_Q_FILE } from '../modules/local/annotate_q_file/main.nf'
include { BCFTOOLS_QUERY as BCFTOOLS_QUERY_SAMPLE_LIST } from '../modules/nf-core/bcftools/query/main.nf'
include { GET_FILTER_STATS } from '../modules/local/get_summary/main.nf'
include { GET_VCF_STATS } from '../modules/local/get_summary/main.nf'
include { GET_SUMMARY } from '../modules/local/get_summary/main.nf'
include { BCFTOOLS_STATS } from '../modules/nf-core/bcftools/stats/main.nf'
workflow RUN_ADMIXTURE_FROM_GLIMPSE {

    if (params.filter_input) {
    
        input_vcf_ch = channel.fromPath(params.test_vcf)
        input_index_ch = channel.fromPath(params.test_vcf_index)
        bcftools_view_input_ch = input_vcf_ch.combine(input_index_ch).map{
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

    } else {
    
        input_vcf_ch = channel.fromPath(params.test_vcf)
        input_index_ch = channel.fromPath(params.test_vcf_index)
        pops_vcf_ch = channel.fromPath(params.pops_vcf)
        pops_index_ch = channel.fromPath(params.pops_vcf_index)
        
        vcf_ch = input_vcf_ch.merge(pops_vcf_ch).map{a, b -> [[id: 'glimpse_unfiltered'], [a, b]]}
        index_ch = input_index_ch.merge(pops_index_ch).map{a, b -> [[id: 'glimpse_unfiltered'], [a, b]]}
    
    }
    
    ref_vcf_ch = pops_vcf_ch.combine(pops_index_ch).map{
        vcf, index -> [[id: 'get_sample_list'], vcf, index]
    }
 
    BCFTOOLS_QUERY_SAMPLE_LIST(ref_vcf_ch, [], [], [])
  
    vcf_ch_1 = input_vcf_ch.combine(input_index_ch).map{
        vcf, index -> [[id: '1_PREFILTER'], vcf, index]
    }

    isec_input_ch = vcf_ch.join(index_ch)

    BCFTOOLS_ISEC( isec_input_ch )
 
    BCFTOOLS_MERGE_FROM_ISEC(BCFTOOLS_ISEC.out.results)

    plink_vcf_input_ch = BCFTOOLS_MERGE_FROM_ISEC.out.merged_variants.map{ meta, vcf, index -> [[id: 'plink_from_vcf'], vcf, index]}
    PLINK2_VCF(plink_vcf_input_ch)

    vcf_ch_2 = plink_vcf_input_ch.map{
        meta, vcf, index -> [[id: '2_BCFTOOLS_MERGE_FROM_ISEC'], vcf, index]
    }

    vcf_stat_input=vcf_ch_1.mix(vcf_ch_2)

    stat_input3=PLINK2_VCF.out.fam.join(PLINK2_VCF.out.bim).combine(BCFTOOLS_QUERY_SAMPLE_LIST.out.output).map{
        meta, fam, bim, meta2, ref -> [[id:"3_PLINK2_VCF"], fam, bim, ref]
    }

    if (params.samples_to_exclude == ""){

        filter_input_ch1 = PLINK2_VCF.out.bed.join(PLINK2_VCF.out.bim).join(PLINK2_VCF.out.fam).map{
            meta, bed, bim, fam -> [[id:'maf_filter', prefix_in:'plink_from_vcf', prefix_out:'plink_maf_filtered'], bed, bim, fam]
        }

    } else {

        remove_input_ch0 = PLINK2_VCF.out.bed.join(PLINK2_VCF.out.bim).join(PLINK2_VCF.out.fam).map{
            meta, bed, bim, fam -> [[id:'remove_samples', prefix_in:'plink_from_vcf', prefix_out:'plink_from_vcf_clean'], bed, bim, fam]
        }
        samples_to_exclude0 = channel.fromPath(params.samples_to_exclude)//.map { file_path -> [ [id:'samples_to_exclude'], file_path ] }
        PLINK2_REMOVE_SELECTED_SAMPLES(remove_input_ch0, samples_to_exclude0)

        stat_input3_5=PLINK2_REMOVE_SELECTED_SAMPLES.out.remove_fam.join(PLINK2_REMOVE_SELECTED_SAMPLES.out.remove_bim).combine(BCFTOOLS_QUERY_SAMPLE_LIST.out.output).map{
            meta, fam, bim, meta2, ref -> [[id:"3.5_REMOVE"], fam, bim, ref]
        }

        filter_input_ch1 = PLINK2_REMOVE_SELECTED_SAMPLES.out.remove_bed.join(PLINK2_REMOVE_SELECTED_SAMPLES.out.remove_bim).join(PLINK2_REMOVE_SELECTED_SAMPLES.out.remove_fam).map{
            meta, bed, bim, fam -> [[id:'maf_filter', prefix_in:'remove_samples', prefix_out:'plink_maf_filtered'], bed, bim, fam]
        }

    }
    PLINK2_MAF_FILTER(filter_input_ch1)

    stat_input4=PLINK2_MAF_FILTER.out.fam.join(PLINK2_MAF_FILTER.out.bim).combine(BCFTOOLS_QUERY_SAMPLE_LIST.out.output).map{
        meta, fam, bim, meta2, ref -> [[id:"4_PLINK2_MAF_FILTER"], fam, bim, ref]
    }

    filter_input_ch2 = PLINK2_MAF_FILTER.out.bed.join(PLINK2_MAF_FILTER.out.bim).join(PLINK2_MAF_FILTER.out.fam).map{
        meta, bed, bim, fam -> [[id:'var_filter', prefix_in:'plink_maf_filtered', prefix_out:'plink_var_filtered'], bed, bim, fam]
    }
    PLINK2_VAR_FILTER(filter_input_ch2)

    stat_input5=PLINK2_VAR_FILTER.out.fam.join(PLINK2_VAR_FILTER.out.bim).combine(BCFTOOLS_QUERY_SAMPLE_LIST.out.output).map{
        meta, fam, bim, meta2, ref -> [[id:"5_PLINK2_VAR_FILTER"], fam, bim, ref]
    }

    filter_input_ch3 = PLINK2_VAR_FILTER.out.bed.join(PLINK2_VAR_FILTER.out.bim).join(PLINK2_VAR_FILTER.out.fam).map{
        meta, bed, bim, fam -> [[id:'sample_filter', prefix_in:'plink_var_filtered', prefix_out:'plink_sample_filtered'], bed, bim, fam]
    }
    PLINK2_SAMPLE_FILTER(filter_input_ch3)

    stat_input6=PLINK2_SAMPLE_FILTER.out.fam.join(PLINK2_SAMPLE_FILTER.out.bim).combine(BCFTOOLS_QUERY_SAMPLE_LIST.out.output).map{
        meta, fam, bim, meta2, ref -> [[id:"6_PLINK2_SAMPLE_FILTER"], fam, bim, ref]
    }

    het_input_ch = PLINK2_SAMPLE_FILTER.out.bed.join(PLINK2_SAMPLE_FILTER.out.bim).join(PLINK2_SAMPLE_FILTER.out.fam).map{
        meta, bed, bim, fam -> [[id:'inbreeding', prefix_in:'plink_sample_filtered', prefix_out:'plink_het'], bed, bim, fam]
    }
    PLINK2_HET(het_input_ch)

    IDENTIFY_HET_OUTLIERS(PLINK2_HET.out.het)

    remove_input_ch = het_input_ch.map{ meta, bed, bim, fam -> [[id:'remove_samples', prefix_in:'plink_sample_filtered', prefix_out:'het_outliers_removed'], bed, bim, fam]}
    samples_to_exclude1 = IDENTIFY_HET_OUTLIERS.out.samples_to_exclude.map { meta, file_path -> [ file_path ] }
    PLINK2_REMOVE(remove_input_ch, samples_to_exclude1)

    stat_input7=PLINK2_REMOVE.out.remove_fam.join(PLINK2_REMOVE.out.remove_bim).combine(BCFTOOLS_QUERY_SAMPLE_LIST.out.output).map{
        meta, fam, bim, meta2, ref -> [[id:"7_PLINK2_HET_FILTER"], fam, bim, ref]
    }

    plink_hwe_input_ch = PLINK2_REMOVE.out.remove_bed.join(PLINK2_REMOVE.out.remove_bim).join(PLINK2_REMOVE.out.remove_fam).map{
        meta, bed, bim, fam -> [[id:'hwe_filter', prefix_in:'remove_samples', prefix_out:'plink_hwe_filter'], bed, bim, fam]
    }

  
    PLINK2_HWE_FILTER(plink_hwe_input_ch)

    stat_input8=PLINK2_HWE_FILTER.out.fam.join(PLINK2_HWE_FILTER.out.bim).combine(BCFTOOLS_QUERY_SAMPLE_LIST.out.output).map{
        meta, fam, bim, meta2, ref -> [[id:"8_PLINK2_HWE_FILTER"], fam, bim, ref]
    }

    plink_prune_input_ch = PLINK2_HWE_FILTER.out.bed.join(PLINK2_HWE_FILTER.out.bim).join(PLINK2_HWE_FILTER.out.fam).map{
        meta, bed, bim, fam -> [[id:'ld_prune', prefix_in:'plink_hwe_filter', prefix_out:'plink_ld_prune'], bed, bim, fam]
    }

    PLINK2_INDEPPAIRWISE(plink_prune_input_ch, params.window_size, params.step, params.r_squared)

    extract_input_ch = plink_prune_input_ch.join(PLINK2_INDEPPAIRWISE.out.prune_in).map{ 
        meta, bed, bim, fam, vars -> [ [id:'ld_prune_extract', prefix_in:'plink_hwe_filter', prefix_out:'plink_ld_pruned'], bed, bim, fam, vars]
        }    
    PLINK2_EXTRACT(extract_input_ch)

    stat_input9=PLINK2_EXTRACT.out.fam.join(PLINK2_EXTRACT.out.bim).combine(BCFTOOLS_QUERY_SAMPLE_LIST.out.output).map{
        meta, fam, bim, meta2, ref -> [[id:"9_PLINK2_INDEP_PAIRWISE_FILTER"], fam, bim, ref]
    }

    if (params.samples_to_exclude == ""){
        extratct_stat_input=stat_input3.mix(stat_input4).mix(stat_input5).mix(stat_input6).mix(stat_input7).mix(stat_input8).mix(stat_input9)
    } else {
        extratct_stat_input=stat_input3.mix(stat_input3_5).mix(stat_input4).mix(stat_input5).mix(stat_input6).mix(stat_input7).mix(stat_input8).mix(stat_input9)
    }

    if (params.supervised_admixture) {
        mode=params.pop_columns
        gpf_input = PLINK2_EXTRACT.out.fam.combine(mode).map{
            meta, fam, mode -> [[id:"get_" + mode], fam, mode]
        }
        //change combine for PLINK2_EXTRACT.outs to join
        GET_POP_FILE(gpf_input, params.sample_column, params.pops_file)
        admix_input_pop = PLINK2_EXTRACT.out.bed.join(PLINK2_EXTRACT.out.bim).join(PLINK2_EXTRACT.out.fam).combine(GET_POP_FILE.out.pop).map{
            meta1, bed,  bim,  fam,  meta2, mode, pop -> [[id:"supervised_admixture_"+ mode], bed, bim, fam, pop]
        }
        SUPERVISED_ADMIXTURE(admix_input_pop)

        pop_ch=GET_POP_FILE.out.pop.map{
            meta, mode, pop -> [[id:"supervised_admixture_"+ mode], pop]
        }

        annotate_input_ch=SUPERVISED_ADMIXTURE.out.ancestry_fractions.join(pop_ch).combine(PLINK2_EXTRACT.out.fam).map{
            meta, qfile, pops, meta2, fam -> [meta, qfile, pops, fam]
        }

        ANNOTATE_SUPERVISED_Q_FILE(annotate_input_ch)
        cv_txt_ch = SUPERVISED_ADMIXTURE.out.cross_validation.collect()

    } else {
        plink_genome_input_ch = PLINK2_EXTRACT.out.bed.join(PLINK2_EXTRACT.out.bim).join(PLINK2_EXTRACT.out.fam).map{
            meta, bed, bim, fam -> [[id:'ibd', prefix_in:'plink_ld_pruned', prefix_out:'plink_ld_pruned'], bed, bim, fam]
        }

        PLINK_GENOME(plink_genome_input_ch)

        FIND_RELATED_SAMPLES(PLINK_GENOME.out.genome)

        remove_related_input_ch = plink_genome_input_ch.map{
            meta, bed, bim, fam -> [[id:'rm_related', prefix_in:'plink_ld_pruned', prefix_out:'plink_remove_related'], bed, bim, fam]
        }
        samples_to_exclude2 = FIND_RELATED_SAMPLES.out.related.map { meta, file_path -> [ file_path ] }
        PLINK2_REMOVE_RELATED(remove_related_input_ch, samples_to_exclude2)

        stat_input10=PLINK2_REMOVE_RELATED.out.remove_fam.join(PLINK2_REMOVE_RELATED.out.remove_bim).combine(BCFTOOLS_QUERY_SAMPLE_LIST.out.output).map{
            meta, fam, bim, meta2, ref -> [[id:"10_PLINK2_REMOVE_RELATED"], fam, bim, ref]
        }

        pca_input_ch = PLINK2_REMOVE_RELATED.out.remove_bed.join(PLINK2_REMOVE_RELATED.out.remove_bim).join(PLINK2_REMOVE_RELATED.out.remove_fam).map{
            meta, bed, bim, fam -> [[id:'pca', prefix_in:'rm_related', prefix_out:'plink_pca'], bed, bim, fam]
        }
        PLINK2_PCA(pca_input_ch)

        k_ch = channel.from(5..13)

        admix_input1_ch = PLINK2_PCA.out.bed.join(PLINK2_PCA.out.bim).join(PLINK2_PCA.out.fam).map{
            meta, bed, bim, fam -> [[id:'admixture'], bed, bim, fam]
        }

        admix_input_ch = admix_input1_ch.combine(k_ch.flatten()).map{
            meta, bed, bim, fam, k -> [[id:"admixture_" + k], bed, bim, fam]
        }

        ADMIXTURE(admix_input_ch, k_ch)

        pops_ch = channel.fromPath(params.pops_file)

        annotate_inpout_ch = ADMIXTURE.out.ancestry_fractions.groupTuple(by: 0).combine(PLINK2_PCA.out.fam).combine(pops_ch).map{
            meta, qfile, meta2, fam, pops -> [meta, qfile, fam, pops]
        }
    
        ANNOTATE_Q_FILE(annotate_inpout_ch)
        cv_txt_ch = ADMIXTURE.out.cross_validation.collect() 
        extratct_stat_input=extratct_stat_input.mix(stat_input10)

    }

    publish_ch = channel.fromPath(params.publishdir)
    MERGE_TXT(cv_txt_ch)
    BCFTOOLS_STATS(vcf_stat_input, [ [], [] ], [ [], [] ], [ [], [] ], [ [], [] ], [ [], [] ])
    GET_VCF_STATS(BCFTOOLS_STATS.out.stats)
    GET_FILTER_STATS(extratct_stat_input)
    merged_ch=GET_VCF_STATS.out.filter_stats.mix(GET_FILTER_STATS.out.filter_stats)
    statsch = merged_ch.map { meta, txt -> txt }.collect()
    GET_SUMMARY(statsch)

}