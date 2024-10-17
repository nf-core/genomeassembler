//
// Run SAMtools stats, flagstat and idxstats
// From https://github.com/nf-core/viralrecon/blob/dev/subworkflows/nf-core/bam_stats_samtools.nf
//

params.options = [:]

include { SAMTOOLS_STATS    } from '../samtools/stats/main'    
include { SAMTOOLS_IDXSTATS } from '../samtools/idxstats/main' 
include { SAMTOOLS_FLAGSTAT } from '../samtools/flagstat/main' 

workflow BAM_STATS_SAMTOOLS {
    take:
    bam_bai // channel: [ val(meta), [ bam ], [bai] ]

    main:
    SAMTOOLS_STATS    ( bam_bai )
    SAMTOOLS_FLAGSTAT ( bam_bai )
    SAMTOOLS_IDXSTATS ( bam_bai )

    emit:
    stats    = SAMTOOLS_STATS.out.stats            // channel: [ val(meta), [ stats ] ]
    flagstat = SAMTOOLS_FLAGSTAT.out.flagstat      // channel: [ val(meta), [ flagstat ] ]
    idxstats = SAMTOOLS_IDXSTATS.out.idxstats      // channel: [ val(meta), [ idxstats ] ]
}