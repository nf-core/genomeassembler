include { MERQURYFK_MERQURYFK } from "$projectDir/modules/nf-core/merquryfk/merquryfk/main"

workflow EVALUATE_KMER_COMPLETENESS {

    take:
    assembly_ch        // input type: [ [ id: 'sample_name' ], [ id:'assemblerX_build1', pri_asm: '/path/to/primary_asm', alt_asm: '/path/to/alternate_asm' ] ]
    fastk_db           // input type: [ [ id: 'sample_name' ], [ file('path/to/reads.hist') ], [ file('/path/to/reads.ktab') ] ]

    main:
    // TODO:: Include Merqury

    MERQURYFK_MERQURYFK (
        fastk_db.combine( assembly_ch.map { metadata, assembly ->
            [
                metadata,
                ( assembly.alt_asm ? [ assembly.pri_asm, assembly.alt_asm ] : assembly.pri_asm ),
                assembly.id
            ]
        }, by: 0 ).map {
            metadata, fastk_hist, fastk_ktab, asm_files, build_name ->
                [
                    metadata + [ build: build_name ],
                    fastk_hist,
                    fastk_ktab,
                    asm_files
                ]
        }
    )
    versions_ch = MERQURYFK_MERQURYFK.out.versions.first()

    emit:
    versions = versions_ch

}
