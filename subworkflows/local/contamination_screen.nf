include { MASH_SCREEN } from "$projectDir/modules/nf-core/mash/screen/main"
include { MASH_FILTER } from "$projectDir/modules/local/mash/filter"

workflow CONTAMINATION_SCREEN {

    take:
    reads_ch
    mash_screen_db_sketch

    main:
    MASH_SCREEN ( reads_ch.transpose(), mash_screen_db_sketch )
    MASH_FILTER ( MASH_SCREEN.out.screen.groupTuple() )

    // TODO: Visualise results

    emit:
    versions = MASH_SCREEN.out.versions.first()
}
