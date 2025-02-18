include { MINIMAP2_ALIGN as ALIGN } from '../../../../modules/nf-core/minimap2/align/main'
include { BAM_STATS_SAMTOOLS as BAM_STATS } from '../../../nf-core/bam_stats_samtools/main'

workflow MAP_TO_REF {
    take:
    in_reads
    ch_refs

    main:
    // Map reads to reference
    in_reads
        .join(ch_refs)
        .set { ch_map_ref_in }

    ALIGN(ch_map_ref_in, true, 'bai', false, false)

    ALIGN.out.bam.set { ch_aln_to_ref_bam }

    ch_aln_to_ref_bam
        .join(ALIGN.out.index)
        .set { ch_aln_to_ref_bam_bai }

    ch_map_ref_in
        .map { meta, _reads, fasta -> [meta, fasta] }
        .set { ch_fasta }

    BAM_STATS(ch_aln_to_ref_bam_bai, ch_fasta)

    emit:
    ch_aln_to_ref_bam
}
