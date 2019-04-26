/*
 * pipeline input parameters
 */
 params.reads = "$baseDir/test-data/fastq/**_{R1,R2}_cdh_lzw_trim30_PF.fastq"
 params.reference = "$baseDir/test-data/fasta/**_contigs.fasta"
 params.outdir = "$baseDir/test-data/results"
// reads actually here s3://czbiohub-mosquito/sequences/CMS_cleaned_reads/
// contigs actually here s3://czbiohub-mosquito/czbiohub-mosquito/contigs/{sample}/contigs.fasta
 println """\
          B O W T I E 2 - N F   P I P E L I N E
          ===================================
          reference    : ${params.reference}
          reads        : ${params.reads}
          outdir       : ${params.outdir}
          """
          .stripIndent()


Channel
  .fromPath(params.reference)
  .set {reference_ch}

process index {
    tag "Index of $sample_id"

    input:
    set sample_id, file(reference) from reference_ch

    output:
    file '${sample_id}' into index_ch

    script:
    """
    bowtie2-build $reference ${sample_id}
    """
}


Channel
    .fromFilePairs(params.reads)
    .ifEmpty { error "Oops! Cannot find any file matching: ${params.reads}"  }
    .into { read_pairs_ch }


process mapping {
    tag "$pair_id"

    input:
    file index from index_ch
    set pair_id, file(reads) from read_pairs_ch

    output:
    file()


    script:
    """
    bowtie2 -p4 -x ${sample} -q -1 ${reads[0]} -2 ${reads[0]} /
    --very-sensitive-local -S ${pair_id}.sam --no-unal \
    --al-conc ${pair_id}_conc.sam 2> ${pair_id}.log
    """
}

process bamify {
    tag "Create bam file of $sample_id"

    input:
    file sam from sam_ch

    output:
    file("fastqc_${sample_id}_logs") into fastqc_ch


    script:
    """
    samtools view -S -b $sam > $bam
    """
}
