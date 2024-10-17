include { ALIGN_SHORT_TO_BAM as ALIGN_SHORT } from '../../../modules/align/main'
include { BAM_INDEX_STATS_SAMTOOLS as BAM_STATS } from '../../../modules/bam_sort_stat/main'

workflow MAP_SR {
  take:
    in_reads
    genome_assembly

  main:
    // map reads to assembly
    in_reads
      .join(genome_assembly)
      .set { map_assembly }

    ALIGN_SHORT(map_assembly)

    ALIGN_SHORT
      .out
      .alignment
      .set { aln_to_assembly_bam }

    BAM_STATS(aln_to_assembly_bam)

    BAM_STATS
      .out
      .bai
      .set { aln_to_assembly_bai }

    aln_to_assembly_bam.
      join(aln_to_assembly_bai)
      .set { aln_to_assembly_bam_bai }

  emit:
    aln_to_assembly_bam
    aln_to_assembly_bai
    aln_to_assembly_bam_bai
}