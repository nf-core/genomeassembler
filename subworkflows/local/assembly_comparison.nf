include { QUAST } from "$projectDir/modules/nf-core/quast/main"

workflow ASSEMBLY_COMPARISON {

    take:
    assembly_ch        // input type: [ [ id: 'sample_name' ], [ id:'assemblerX_build1', pri_asm: '/path/to/primary_asm', alt_asm: '/path/to/alternate_asm' ] ]
    reference_ch       // optional: file( reference_genome ) for comparison

    main:
    // Assembly statistics comparison
    QUAST (
        assembly_ch.map { sample, assembly -> assembly.pri_asm }
            .collect(),
        reference_ch,
        [], // gff
        reference_ch, // true / false to use reference_ch
        []
    )
    versions_ch = QUAST.out.versions

    // Assembly synteny

    emit:
    versions = versions_ch

}
