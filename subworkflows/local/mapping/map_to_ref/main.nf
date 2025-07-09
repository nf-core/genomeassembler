include { MINIMAP2_ALIGN as ALIGN } from '../../../../modules/nf-core/minimap2/align/main'
include { BAM_STATS_SAMTOOLS as BAM_STATS } from '../../../nf-core/bam_stats_samtools/main'

workflow MAP_TO_REF {
    take:
    ch_map_ref // meta: [id, qc_reads], reads, refs

    main:
    Channel.empty().set { ch_versions }

    // Map reads to reference
    ALIGN(ch_map_ref, true, 'bai', false, false)

    ALIGN.out.bam
        .map { meta, bam -> [ [id: meta.id], bam ] }
        .set { ch_aln_to_ref_bam }

    ALIGN.out.index
        .map {meta, bai -> [ [id: meta.id], bai ]}
        .set { aln_to_ref_bai }

    ch_aln_to_ref_bam
        .join(aln_to_ref_bai)
        .set { ch_aln_to_ref_bam_bai }

    ch_map_ref
        .map { meta, _reads, fasta -> [[id: meta.id], fasta] }
        .set { ch_fasta }

    BAM_STATS(ch_aln_to_ref_bam_bai, ch_fasta)

    versions = ch_versions.mix(ALIGN.out.versions).mix(BAM_STATS.out.versions)

    emit:
    ch_aln_to_ref_bam //  [id], bam
    versions
}
