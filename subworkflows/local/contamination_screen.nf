include { MASH_SKETCH } from "$projectDir/modules/nf-core/mash/sketch/main"
include { MASH_SCREEN } from "$projectDir/modules/nf-core/mash/screen/main"
include { MASH_FILTER } from "$projectDir/modules/local/mash/filter"

workflow CONTAMINATION_SCREEN {

    take:
    ch_reads
    mash_screen_db

    main:
    mash_screen_db.branch {
        sketch: it.name.endsWith('.msh')
        fasta : it.name.endsWith('.fasta')
            return [ [ id: it.baseName ], it ] // Reformat for MASH_SKETCH
    }.set { ch_mash_screen }
    MASH_SKETCH ( ch_mash_screen.fasta )
    MASH_SCREEN (
        ch_reads.transpose(),
        ch_mash_screen.sketch
            .mix( MASH_SKETCH.out.mash
                .map { meta, sketch -> sketch }
            ).collect()
    )
    // TODO: Replace with GAWK or MILLER? module
    MASH_FILTER ( MASH_SCREEN.out.screen.groupTuple() )

    // TODO: Visualise results

    emit:
    versions = MASH_SCREEN.out.versions.first()
}
