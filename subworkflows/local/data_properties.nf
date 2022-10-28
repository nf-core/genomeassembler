include { FASTQC   } from "$projectDir/modules/nf-core/fastqc/main"
include { NANOPLOT } from "$projectDir/modules/nf-core/nanoplot/main"

workflow DATA_PROPERTIES {

    take:
    fastx_ch
    is_short_reads   // Boolean

    main:
    logs_ch     = Channel.empty()
    versions_ch = Channel.empty()

    fastx_ch.branch {
        short_reads: is_short_reads
        long_reads: !is_short_reads
    }.set { sequence_ch }

    FASTQC( sequence_ch.short_reads )
    logs_ch = logs_ch.mix( FASTQC.out.zip.map{ meta, zip -> zip } )
    versions_ch = versions_ch.mix( FASTQC.out.versions.first() )

    // MinionQC

    NANOPLOT( sequence_ch.long_reads )
    logs_ch = logs_ch.mix( NANOPLOT.out.log.map{ meta, log -> log } )
    versions_ch = versions_ch.mix( FASTQC.out.versions.first() )

    emit:
    logs     = logs_ch
    versions = versions_ch
}
