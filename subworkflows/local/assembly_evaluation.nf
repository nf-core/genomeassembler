include { MERQURYFK_MERQURYFK } from "$projectDir/modules/nf-core/merquryfk/merquryfk/main"

workflow ASSEMBLY_EVALUATION {

    take:
    assembly_ch        // input type: [ [ id: 'sample_name' ], [ id:'assemblerX_build1', pri_asm: '/path/to/primary_asm', alt_asm: '/path/to/alternate_asm' ] ]
    reads_ch           // input type: [ [ id: 'sample_name' ], [ file('path/to/reads') ] ]
    fastk_db           // input type: [ [ id: 'sample_name' ], [ file('path/to/reads.hist') ], [ file('/path/to/reads.ktab') ] ]

    main:

    // Kmer consistency check
    MERQURYFK_MERQURYFK (
        fastk_db.combine( assembly_ch.map { sample, assembly ->
            [
                sample,
                ( assembly.alt_asm ? [ assembly.pri_asm, assembly.alt_asm ] : assembly.pri_asm ),
                assembly.id
            ]
        }, by: 0 ).map {
            sample, fastk_hist, fastk_ktab, asm_files, build_name ->
                [
                    [ id: sample.id , build: build_name ],
                    fastk_hist,
                    fastk_ktab,
                    asm_files
                ]
        }
    )
    versions_ch = MERQURYFK_MERQURYFK.out.versions.first()

    // Read alignment

    // Contamination

    // GC vs Coverage

    emit:
    versions = versions_ch
}
