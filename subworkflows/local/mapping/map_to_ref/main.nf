include { ALIGN_SHORT_TO_BAM as ALIGN_SHORT } from '../../../../modules/local/align/main'
include { BAM_INDEX_STATS_SAMTOOLS as BAM_STATS } from '../../../../modules/local/bam_sort_stat/main'

workflow MAP_TO_REF {
  take: 
    in_reads
    ch_refs

  main:
    // Map reads to reference
    in_reads
      .join(ch_refs)
      .set { ch_map_ref_in }

    ALIGN(ch_map_ref_in)

    ALIGN
      .out
      .alignment
      .set { ch_aln_to_ref }

    BAM_STATS(ch_aln_to_ref)

  emit:
    ch_aln_to_ref
}