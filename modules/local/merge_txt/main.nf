process MERGE_TXT {
    label 'process_low'
  
    publishDir "${params.publishdir}", mode: 'copy', pattern: "merged_cv.txt"
  
    input:
    path(cv_txt_ch)

    output:
    path("merged_cv.txt"),  emit: merged_cv_file

    script:
    """
    # Concatenate all .txt files
    cat ${cv_txt_ch} | sort -Vk3 > merged_cv.txt
    """
}
