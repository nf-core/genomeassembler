include { MINIMAP2_ALIGN as ALIGN_SHORT } from '../../../../modules/nf-core/minimap2/align/main'
include { BAM_STATS_SAMTOOLS as BAM_STATS } from '../../../nf-core/bam_stats_samtools/main'

workflow MAP_SR {
    take:
    in_reads
    genome_assembly

    main:
    Channel.empty().set { ch_versions }
    // map reads to assembly
    in_reads
        .map { meta, reads -> [[id: meta.id], reads] }
        .join(genome_assembly)
        .set { map_assembly }

    ALIGN_SHORT(map_assembly, true, 'csi', false, false)

    versions = ch_versions.mix(ALIGN_SHORT.out.versions)

    ALIGN_SHORT.out.bam.set { aln_to_assembly_bam }

    ALIGN_SHORT.out.index.set { aln_to_assembly_csi }

    aln_to_assembly_bam
        .join(aln_to_assembly_csi)
        .set { aln_to_assembly_bam_csi }

    map_assembly
        .map { meta, _reads, fasta -> [ meta, fasta ] }
        .set { ch_fasta }

    BAM_STATS(aln_to_assembly_bam_csi, ch_fasta)

    versions = ch_versions.mix(BAM_STATS.out.versions)

    aln_to_assembly_bam
        .join(aln_to_assembly_csi)
        .set { aln_to_assembly_bam_csi }

    emit:
    aln_to_assembly_bam
    aln_to_assembly_csi
    aln_to_assembly_bam_csi
    versions
}
