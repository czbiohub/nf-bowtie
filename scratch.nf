/*
 * pipeline input parameters
 */
 params.reads = "$baseDir/test-data/fastq/**_{R1,R2}_cdh_lzw_trim30_PF.fastq"
 params.reference = "$baseDir/test-data/fasta/**_contigs.fasta"
 params.outdir = "$baseDir/test-data/results"
// reads  here s3://czbiohub-mosquito/sequences/CMS_cleaned_reads/
// contigs  here s3://czbiohub-mosquito/czbiohub-mosquito/contigs/{sample}/contigs.fasta
 println """\
          B O W T I E 2 - N F   P I P E L I N E
          ===================================
          reference    : ${params.reference}
          reads        : ${params.reads}
          outdir       : ${params.outdir}
          """
          .stripIndent()


ch_multiqc_config = Channel.fromPath(params.multiqc_config)

// /*
//  * Parse software version numbers
//  */
// process get_software_versions {
//     publishDir "${params.outdir}/pipeline_info", mode: 'copy',
//     saveAs: {filename ->
//         if (filename.indexOf(".csv") > 0) filename
//         else null
//     }
//
//     output:
//     file 'software_versions_mqc.yaml' into software_versions_yaml
//     file "software_versions.csv"
//
//     script:
//     // TODO nf-core: Get all tools to print their version number here
//     """
//     echo $workflow.manifest.version > v_pipeline.txt
//     echo $workflow.nextflow.version > v_nextflow.txt
//     samtools --version &> v_samtools.txt
//     scrape_software_versions.py &> software_versions_mqc.yaml
//     """
// }
//


process build_reference {
publishDir params.outdir, mode:'copy'

output:
file 'reference' into reference_ch

script:
"""
cat ${params.reference} > reference
"""
}


process index {

input:
file reference from reference_ch

output:
file 'index*' into index_ch

script:
"""
bowtie2-build $reference index
"""
  }


Channel
  .fromFilePairs( params.reads )
  .ifEmpty { error "Oops! Cannot find any file matching: ${params.reads}"  }
  .into { read_pairs_ch; read_pairs2_ch }
  //read_pairs_ch.println()
  //read_pairs2_ch.println()

process mapping {
    tag "$pair_id"

    input:
    file index from index_ch
    set pair_id, file(reads) from read_pairs_ch

    output:
    set val(pair_id), file("${pair_id}.sam") into aligned_sam //want the sam file pumped to channel only and log file saved
    file "${pair_id}.log" into bowtie_logs

    script:
    """
    bowtie2 \\
        --threads $task.cpus \\
        -x $index \\
        -q -1 ${reads[0]} -2 ${reads[1]} \\
        --very-sensitive-local \\
        -S ${pair_id}.sam \\
        --no-unal \\
        2>&1 | tee ${pair_id}.log
    """


}

process bamify {
    tag "Create bam file of $sample_id"
    publishDir params.outdir, mode:'copy'

    input:
    set val(pair_id), file(sam) from aligned_sam

    output:
    set val(pair_id), file("${pair_id}.bam") into bam_ch, bam_stats_ch


    script:
    """
    samtools view -S -b $sam > ${pair_id}.bam
    """
}

process samtools_sort_index {
    tag "Sort and index bam files"
    publishDir "${params.outdir}/samtools", mode:'copy'

    input:
    set val(pair_id), file(bam) from bam_stats_ch

    output:
    file "${pair_id}.sorted.bam" into sorted_bam
    file "*stat*" into samtools_stats

    script:
    """
    samtools sort \\
            $bam \\
            -@ ${task.cpus} \\
            -o ${pair_id}.sorted.bam
    samtools index ${pair_id}.sorted.bam
    samtools flagstat ${pair_id}.sorted.bam > ${pair_id}.flagstats
    samtools stats ${pair_id}.sorted.bam > ${pair_id}.stats
    samtools idxstats ${pair_id}.sorted.bam > ${pair_id}.idxstats
    """
}

// process count_reads { //calling foo.py in folder... naming
// publishDir params.outdir, mode:'copy'
//
//   input:
//   file bam from bam_ch
//
//   script:
//   """
//   samtools view -f 0x2 $bam | grep -v "XS:i:" | ./foo.py | cut -f 3 | sort | uniq -c | awk '{printf("%s\t%s\n", $2, $1)}' > /mnt/data/outputs/bowtie_csp_counts.txt
//   samtools view -F 260 $bam | cut -f 3 | sort | uniq -c | awk '{printf("%s\t%s\n", $2, $1)}'  > /mnt/data/outputs/bowtie_all_counts.txt
//   samtools view -f 0x2 $bam | grep -v "XS:i:" | cut -f 3 | sort | uniq -c | awk '{printf("%s\t%s\n", $2, $1)}' > /mnt/data/outputs/bowtie_cs_counts.txt
//   """
// }
// workflow.onComplete {
// 	println ( workflow.success ? "\nDone! Open the following report in your browser --> $params.outdir/multiqc_report.html\n" : "Oops .. something went wrong" )
// }

/*
 * STEP 12 MultiQC
 */
process multiqc {
    publishDir "${params.outdir}/MultiQC", mode: 'copy'

    when:
    !params.skip_multiqc

    input:
    file multiqc_config from ch_multiqc_config
    // file (fastqc:'fastqc/*') from fastqc_results.collect().ifEmpty([])
    file ('samtools/*') from samtools_stats.collect().ifEmpty([])
    // file ('software_versions/*') from software_versions_yaml
    // file workflow_summary from create_workflow_summary(summary)

    output:
    file "*multiqc_report.html" into multiqc_report
    file "*_data"

    script:
    rtitle = custom_runName ? "--title \"$custom_runName\"" : ''
    rfilename = custom_runName ? "--filename " + custom_runName.replaceAll('\\W','_').replaceAll('_+','_') + "_multiqc_report" : ''
    """
    multiqc . -f $rtitle $rfilename --config $multiqc_config \\
        -m custom_content -m samtools
    """
}
