include { MASH_SCREEN } from "$projectDir/modules/nf-core/mash/screen/main"
include { MASH_FILTER } from "$projectDir/modules/local/mash/filter"

workflow CONTAMINATION_SCREEN {

    take:
    ch_reads
    mash_screen_db

    main:
    MASH_SCREEN ( ch_reads.transpose(), mash_screen_db )
    // TODO: Replace with GAWK or MILLER? module
    MASH_FILTER ( MASH_SCREEN.out.screen.groupTuple() )

    // TODO: Visualise results

    emit:
    versions = MASH_SCREEN.out.versions.first()
}
