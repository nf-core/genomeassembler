include { BUSCO } from "$projectDir/modules/nf-core/busco/main"

workflow EVALUATE_GENE_SPACE {

    take:
    assembly_ch        // input type: [ meta w. build id , [ pri_asm: '/path/to/primary_asm', alt_asm: '/path/to/alternate_asm' ] ]
    busco_lineages     // Busco lineages to check against
    busco_lineage_path // Path to Busco lineage files

    main:
    BUSCO (
        assembly_ch.map { meta, assembly -> [ meta, assembly.pri_asm ] },  // Evalute gene space of primary assembly
        busco_lineages,
        busco_lineage_path,
        []
    )
    versions_ch = BUSCO.out.versions.first()

    emit:
    versions = versions_ch

}
