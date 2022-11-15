include { NANOPLOT } from "$projectDir/modules/nf-core/nanoplot/main"

workflow ONT_DATA_PROPERTIES {

    take:
    fastx_ch

    main:
    logs_ch     = Channel.empty()
    versions_ch = Channel.empty()

    // MinionQC

    NANOPLOT( fastx_ch )
    logs_ch = logs_ch.mix( NANOPLOT.out.log.map{ meta, log -> log } )
    versions_ch = versions_ch.mix( FASTQC.out.versions.first() )

    emit:
    logs     = logs_ch
    versions = versions_ch
}
