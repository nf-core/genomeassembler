//
// Sort, index BAM file and run samtools stats, flagstat and idxstats
// from https://github.com/nf-core/viralrecon/blob/dev/subworkflows/nf-core/bam_sort_samtools.nf
//

params.samtools_sort_options  = [:]
params.samtools_index_options = [:]
params.bam_stats_options      = [:]

include { SAMTOOLS_SORT      } from '../samtools/sort/main'  addParams( options: params.samtools_sort_options )
include { SAMTOOLS_INDEX     } from '../samtools/index/main' addParams( options: params.samtools_index_options )
include { BAM_STATS_SAMTOOLS } from './bam_stats_samtools'  addParams( options: params.bam_stats_options )
include { SAMTOOLS_GET_UNMAPPED  } from '../samtools/unmapped/main' addParams( options: params.bam_stats_options )

workflow BAM_SORT_SAMTOOLS {
    take:
    bam // channel: [ val(meta), [ bam ] ]

    main:
    SAMTOOLS_SORT      ( bam )
    SAMTOOLS_INDEX     ( SAMTOOLS_SORT.out.bam )
    BAM_STATS_SAMTOOLS ( SAMTOOLS_SORT.out.bam.join(SAMTOOLS_INDEX.out.bai, by: [0]) )

    emit:
    //bam      = SAMTOOLS_SORT.out.bam              // channel: [ val(meta), [ bam ] ]
    bai      = SAMTOOLS_INDEX.out.bai             // channel: [ val(meta), [ bai ] ]
    stats    = BAM_STATS_SAMTOOLS.out.stats       // channel: [ val(meta), [ stats ] ]
    flagstat = BAM_STATS_SAMTOOLS.out.flagstat    // channel: [ val(meta), [ flagstat ] ]
    idxstats = BAM_STATS_SAMTOOLS.out.idxstats    // channel: [ val(meta), [ idxstats ] ]
    samtools_version  = SAMTOOLS_SORT.out.version //    path
}

workflow BAM_INDEX_STATS_SAMTOOLS {
    take:
    bam // channel: [ val(meta), [ bam ] ]

    main:

    SAMTOOLS_INDEX     ( bam )
    BAM_STATS_SAMTOOLS ( bam.join(SAMTOOLS_INDEX.out.bai, by: [0]) )

    emit:
    bai      = SAMTOOLS_INDEX.out.bai             // channel: [ val(meta), [ bai ] ]
    stats    = BAM_STATS_SAMTOOLS.out.stats       // channel: [ val(meta), [ stats ] ]
    flagstat = BAM_STATS_SAMTOOLS.out.flagstat    // channel: [ val(meta), [ flagstat ] ]
    idxstats = BAM_STATS_SAMTOOLS.out.idxstats    // channel: [ val(meta), [ idxstats ] ]
    //samtools_version  = SAMTOOLS_SORT.out.version //    path
}


workflow BAM_GET_UNMAPPED_SAMTOOLS {
    take:
    bam // channel: [ val(meta), [ bam ] ]

    main:
    SAMTOOLS_GET_UNMAPPED  ( bam )
    SAMTOOLS_INDEX     ( bam )
    BAM_STATS_SAMTOOLS ( bam.join(SAMTOOLS_INDEX.out.bai, by: [0]) )

    emit:
    bai      = SAMTOOLS_INDEX.out.bai             // channel: [ val(meta), [ bai ] ]
    stats    = BAM_STATS_SAMTOOLS.out.stats       // channel: [ val(meta), [ stats ] ]
    flagstat = BAM_STATS_SAMTOOLS.out.flagstat    // channel: [ val(meta), [ flagstat ] ]
    idxstats = BAM_STATS_SAMTOOLS.out.idxstats    // channel: [ val(meta), [ idxstats ] ]
    unmapped = SAMTOOLS_GET_UNMAPPED.out.unmapped_fq  // channel: [ val (meata), [unmapped_R1, unmapped_R2]]
    //samtools_version  = SAMTOOLS_SORT.out.version //    path
}