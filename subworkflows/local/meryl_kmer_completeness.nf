include { MERQURY } from "$projectDir/modules/nf-core/merqury/main"

workflow MERYL_KMER_COMPLETENESS {

    take:
    assembly_ch        // input type: [ [ id: 'sample_name' ], [ id:'assemblerX_build1', pri_asm: '/path/to/primary_asm', alt_asm: '/path/to/alternate_asm' ] ]
    meryl_db           // input type: [ [ id: 'sample_name' ], [ file('meryl_db') ] ]

    main:
    MERQURY (
        meryl_db.combine( assembly_ch.map { metadata, assembly ->
            [
                metadata,
                ( assembly.alt_asm ? [ assembly.pri_asm, assembly.alt_asm ] : assembly.pri_asm ),
                assembly.id
            ]
        }, by: 0 ).map {
            metadata, meryldb, asm_files, build_name ->
                [
                    metadata + [ build: build_name ],
                    meryldb,
                    asm_files
                ]
        }
    )
    versions_ch = MERQURY.out.versions.first()

    emit:
    versions = versions_ch

}
