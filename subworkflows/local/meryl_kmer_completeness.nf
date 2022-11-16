include { MERQURY } from "$projectDir/modules/nf-core/merqury/main"

workflow MERYL_KMER_COMPLETENESS {

    take:
    assembly_ch        // input type: [ [ id: 'sample_name', build: 'assemblerX_build1' ], [ pri_asm: '/path/to/primary_asm', alt_asm: '/path/to/alternate_asm' ] ]
    meryl_db           // input type: [ [ id: 'sample_name' ], [ file('meryl_db') ] ]

    main:
    MERQURY (
        meryl_db.map{ meta, meryldb -> [ meta.findAll{ !(it in ['single_end']) }, meryldb ] }
            .combine( assembly_ch.map { meta, assembly ->
                [
                    meta.findAll { !(it in ['build'] ) },
                    ( assembly.alt_asm ? [ assembly.pri_asm, assembly.alt_asm ] : assembly.pri_asm ),
                    meta.build
                ]
            }, by: 0 )
            .map { meta, meryldb, assembly, buildid -> [ meta + [ build: buildid ], meryldb, assembly ] }
    )
    versions_ch = MERQURY.out.versions.first()

    emit:
    versions = versions_ch

}
