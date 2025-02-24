include { MINIMAP2_ALIGN as ALIGN } from '../../../../modules/nf-core/minimap2/align/main'
include { BAM_STATS_SAMTOOLS as BAM_STATS } from '../../../nf-core/bam_stats_samtools/main'

workflow MAP_TO_ASSEMBLY {
    take:
    in_reads
    genome_assembly

    main:
    Channel.empty().set { ch_versions }
    // map reads to assembly
    in_reads
        .join(genome_assembly)
        .set { map_assembly }

    ALIGN(map_assembly, true, 'bai', false, false)

    ALIGN.out.bam.set { aln_to_assembly_bam }
    ALIGN.out.index.set { aln_to_assembly_bai }

    map_assembly
        .map { meta, _reads, fasta -> [meta, fasta] }
        .set { ch_fasta }

    aln_to_assembly_bam
        .join(aln_to_assembly_bai)
        .set { aln_to_assembly_bam_bai }

    BAM_STATS(aln_to_assembly_bam_bai, ch_fasta )

    versions = ch_versions.mix(ALIGN.out.versions).mix(BAM_STATS.out.versions)

    emit:
    aln_to_assembly_bam
    versions
}
