include { MINIMAP2_ALIGN as ALIGN } from '../../../../modules/nf-core/minimap2/align/main'
include { BAM_STATS_SAMTOOLS as BAM_STATS } from '../../../nf-core/bam_stats_samtools/main'
include { SAMTOOLS_FAIDX } from '../../../../modules/nf-core/samtools/faidx/main'
include { GUNZIP } from '../../../../modules/nf-core/gunzip/main'

workflow MAP_TO_REF {
    take:
    ch_map_ref // meta, reads, refs

    main:
    // Map reads to reference
    ALIGN(ch_map_ref, true, 'bai', false, false)

    ch_aln_to_ref_bam = ALIGN.out.bam

    aln_to_ref_bai = ALIGN.out.index
    // create index
    ch_index_in = ch_map_ref
        .map { meta, _reads, refs ->
            [
                meta,
                refs
            ]
    }

    GUNZIP(ch_index_in)

    SAMTOOLS_FAIDX(GUNZIP.out.gunzip, false)

    ch_fasta_fai = ch_index_in
        .join(SAMTOOLS_FAIDX.out.fai)

    ch_aln_to_ref_bam_bai = ch_aln_to_ref_bam
        .join(aln_to_ref_bai)

    BAM_STATS(ch_aln_to_ref_bam_bai, ch_fasta_fai)

    emit:
    ch_aln_to_ref_bam //  meta, bam
    stats = BAM_STATS.out.stats
}
