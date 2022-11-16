include { MERYL_COUNT     } from "$projectDir/modules/nf-core/meryl/count/main"
include { MERYL_UNIONSUM  } from "$projectDir/modules/nf-core/meryl/unionsum/main"
include { MERYL_HISTOGRAM } from "$projectDir/modules/nf-core/meryl/histogram/main"

workflow BUILD_MERYL_DATABASES {

    take:
    fastx_data // [ meta, [ fastx ] ]

    main:
    MERYL_COUNT ( fastx_data )
    MERYL_UNIONSUM ( MERYL_COUNT.out.meryl_db.groupTuple() )
    MERYL_HISTOGRAM ( MERYL_UNIONSUM.out.meryl_db )
    versions_ch = versions_ch.mix(
        MERYL_COUNT.out.versions.first(),
        MERYL_UNIONSUM.out.versions.first(),
        MERYL_HISTOGRAM.out.versions.first()
    )

    emit:
    histogram = MERYL_HISTOGRAM.out.hist
    uniondb   = MERYL_UNIONSUM.out.meryl_db
    versions  = versions_ch
}
