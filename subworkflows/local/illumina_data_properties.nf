include { FASTQC } from "$projectDir/modules/nf-core/fastqc/main"

workflow ILLUMINA_DATA_PROPERTIES {

    take:
    fastx_ch

    main:
    logs_ch     = Channel.empty()
    versions_ch = Channel.empty()

    FASTQC( fastx_ch )
    logs_ch = logs_ch.mix( FASTQC.out.zip.map{ meta, zip -> zip } )
    versions_ch = versions_ch.mix( FASTQC.out.versions.first() )

    emit:
    logs     = logs_ch
    versions = versions_ch
}
