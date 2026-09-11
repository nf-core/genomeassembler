include { MINIMAP2_ALIGN as ALIGN } from '../../../../modules/nf-core/minimap2/align/main'
include { BAM_STATS_SAMTOOLS as BAM_STATS } from '../../../nf-core/bam_stats_samtools/main'
include { SAMTOOLS_FAIDX } from '../../../../modules/nf-core/samtools/faidx/main'

workflow MAP_TO_ASSEMBLY {
    take:
    map_assembly // meta: [id, qc_reads], reads, refs

    main:
    ALIGN(map_assembly, true, 'bai', false, false)

    aln_to_assembly_bam = ALIGN.out.bam

    aln_to_assembly_bai = ALIGN.out.index

    ch_index_in = map_assembly
        .map { meta, _reads, refs ->
        [
            meta,
            refs
        ]
    }

    SAMTOOLS_FAIDX(ch_index_in, false)

    ch_fasta_fai = ch_index_in
        .join(SAMTOOLS_FAIDX.out.fai)

    aln_to_assembly_bam_bai = aln_to_assembly_bam
        .join(aln_to_assembly_bai)

    BAM_STATS(aln_to_assembly_bam_bai, ch_fasta_fai)

    emit:
    aln_to_assembly_bam //  [id], bam
    stats = BAM_STATS.out.stats
}
