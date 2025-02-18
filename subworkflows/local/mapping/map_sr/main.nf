include { MINIMAP2_ALIGN as ALIGN_SHORT } from '../../../../modules/nf-core/minimap2/align/main'
include { BAM_STATS_SAMTOOLS as BAM_STATS } from '../../../nf-core/bam_stats_samtools/main'

workflow MAP_SR {
    take:
    in_reads
    genome_assembly

    main:
    // map reads to assembly
    in_reads
        .map { meta, reads -> [[id: meta.id], reads] }
        .join(genome_assembly)
        .set { map_assembly }

    ALIGN_SHORT(map_assembly, true, 'bai', false, false)

    ALIGN_SHORT.out.bam.set { aln_to_assembly_bam }

    ALIGN_SHORT.out.index.set { aln_to_assembly_bai }

    aln_to_assembly_bam
        .join(aln_to_assembly_bai)
        .set { aln_to_assembly_bam_bai }

    map_assembly
        .map { meta, _reads, fasta -> [ meta, fasta ] }
        .set { ch_fasta }

    BAM_STATS(aln_to_assembly_bam_bai, ch_fasta)

    aln_to_assembly_bam
        .join(aln_to_assembly_bai)
        .set { aln_to_assembly_bam_bai }

    emit:
    aln_to_assembly_bam
    aln_to_assembly_bai
    aln_to_assembly_bam_bai
}
