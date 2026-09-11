include { MINIMAP2_ALIGN as ALIGN_SHORT } from '../../../../modules/nf-core/minimap2/align/main'
include { BAM_STATS_SAMTOOLS as BAM_STATS } from '../../../nf-core/bam_stats_samtools/main'
include { SAMTOOLS_FAIDX } from '../../../../modules/nf-core/samtools/faidx/main'
include { GUNZIP } from '../../../../modules/nf-core/gunzip/main'

workflow MAP_SR {
    take:
    in_reads
    genome_assembly

    main:
    // map reads to assembly
    map_assembly = in_reads
        .join(genome_assembly)

    ALIGN_SHORT(map_assembly, true, 'bai', false, false)

    aln_to_assembly_bam = ALIGN_SHORT.out.bam

    aln_to_assembly_bai = ALIGN_SHORT.out.index

    aln_to_assembly_bam_bai = aln_to_assembly_bam
        .join(aln_to_assembly_bai)

    SAMTOOLS_FAIDX(genome_assembly, false)

    ch_fasta_fai = genome_assembly
        .join(SAMTOOLS_FAIDX.out.fai)

    BAM_STATS(aln_to_assembly_bam_bai, ch_fasta_fai)

    aln_to_assembly_bam_bai = aln_to_assembly_bam
        .join(aln_to_assembly_bai)

    emit:
    aln_to_assembly_bam
    aln_to_assembly_bai
    aln_to_assembly_bam_bai
}
