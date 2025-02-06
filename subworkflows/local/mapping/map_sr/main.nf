include { MINIMAP2_ALIGN as ALIGN_SHORT } from '../../../../modules/nf-core/minimap2/align/main'
include { BAM_INDEX_STATS_SAMTOOLS as BAM_STATS } from '../../bam_sort_stat/main'

workflow MAP_SR {
    take:
    in_reads
    genome_assembly

    main:
    // map reads to assembly
    in_reads
        .map { it -> [[id: it[0].id], it[0].paired, it[1]] }
        .join(genome_assembly)
        .set { map_assembly }

    ALIGN_SHORT(map_assembly, true, false, false, false)

    ALIGN_SHORT.out.bam.set { aln_to_assembly_bam }

    map_assembly
        .map { meta, _paired, _reads, fasta -> [ meta, fasta ] }
        .set { ch_fasta }

    BAM_STATS(aln_to_assembly_bam, ch_fasta)

    BAM_STATS.out.bai.set { aln_to_assembly_bai }

    aln_to_assembly_bam
        .join(aln_to_assembly_bai)
        .set { aln_to_assembly_bam_bai }

    emit:
    aln_to_assembly_bam
    aln_to_assembly_bai
    aln_to_assembly_bam_bai
}
