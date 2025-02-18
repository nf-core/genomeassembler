
include { SAMTOOLS_INDEX } from '../../../modules/nf-core/samtools/index/main'
include { BAM_STATS_SAMTOOLS } from '../../nf-core/bam_stats_samtools/main'

//
// Sort, index BAM file and run samtools stats, flagstat and idxstats
// from https://github.com/nf-core/viralrecon/blob/dev/subworkflows/nf-core/bam_sort_samtools.nf
//

params.samtools_sort_options = [:]
params.samtools_index_options = [:]
params.bam_stats_options = [:]

workflow BAM_INDEX_STATS_SAMTOOLS {
    take:
    bam // channel: [ val(meta), [ bam ] ]
    fasta

    main:
    Channel.empty().set { ch_versions }

    SAMTOOLS_INDEX(bam)

    BAM_STATS_SAMTOOLS(bam.join(SAMTOOLS_INDEX.out.bai, by: [0]), fasta)

    versions = ch_versions.mix(SAMTOOLS_INDEX.out.versions).mix(BAM_STATS_SAMTOOLS.out.versions)

    emit:
    bai = SAMTOOLS_INDEX.out.bai // channel: [ val(meta), [ bai ] ]
    stats = BAM_STATS_SAMTOOLS.out.stats // channel: [ val(meta), [ stats ] ]
    flagstat = BAM_STATS_SAMTOOLS.out.flagstat // channel: [ val(meta), [ flagstat ] ]
    idxstats = BAM_STATS_SAMTOOLS.out.idxstats // channel: [ val(meta), [ idxstats ] ]
    versions
}
