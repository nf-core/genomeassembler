include { MERQURYFK_MERQURYFK } from "$projectDir/modules/nf-core/merquryfk/merquryfk/main"

workflow FASTK_KMER_COMPLETENESS {

    take:
    assembly_ch        // input type: [ [ id: 'sample_name', build: 'assemblerX_build1' ], [ pri_asm: '/path/to/primary_asm', alt_asm: '/path/to/alternate_asm' ] ]
    fastk_db           // input type: [ [ id: 'sample_name' ], [ file('path/to/reads.hist') ], [ file('/path/to/reads.ktab') ] ]

    main:
    MERQURYFK_MERQURYFK (
        fastk_db.map{ meta, hist, ktab -> [ meta.findAll{ !(it in ['single_end']) }, hist, ktab ] }
            .combine( assembly_ch.map { meta, assembly ->
                [
                    meta.findAll { !(it in ['build']) },
                    ( assembly.alt_asm ? [ assembly.pri_asm, assembly.alt_asm ] : assembly.pri_asm ),
                    meta.build
                ]
            }, by: 0 )
            .map { meta, hist, ktab, assembly, buildid -> [ meta + [ build: buildid ], hist, ktab, assembly ] }
    )
    versions_ch = MERQURYFK_MERQURYFK.out.versions.first()

    emit:
    versions = versions_ch

}
