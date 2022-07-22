params.skip_fastqc   = false
params.skip_nanoplot = false

include { FASTQC   } from "$projectDir/modules/nf-core/modules/fastqc/main"
include { NANOPLOT } from "$projectDir/modules/nf-core/modules/nanoplot/main"

workflow DATA_PROPERTIES {

    take:
    fastx_ch

    main:
    logs_ch     = Channel.empty()
    versions_ch = Channel.empty()

    if( params.skip_fastqc ){
        FASTQC( fastx_ch )
        logs_ch = logs_ch.mix( FASTQC.out.zips.map{ meta, zips -> zips } )
        versions_ch = versions_ch.mix( FASTQC.out.versions.first() )
    }

    // MinionQC

    if( params.skip_nanoplot ){
        NANOPLOT( fastx_ch )
        logs_ch = logs_ch.mix( NANOPLOT.out.log.map{ meta, log -> log } )
        versions_ch = versions_ch.mix( FASTQC.out.versions.first() )
    }

    emit:
    logs     = logs_ch
    versions = versions_ch
}
