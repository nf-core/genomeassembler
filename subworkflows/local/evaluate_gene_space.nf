include { BUSCO } from "$projectDir/modules/nf-core/busco/main"

workflow EVALUATE_GENE_SPACE {

    take:
    assembly_ch        // input type: [ meta, [ pri_asm: '/path/to/primary_asm', alt_asm: '/path/to/alternate_asm' ] ]
    busco_lineage_path // Path to Busco lineage files

    main:
    BUSCO (
        assembly_ch.map { meta, assembly -> meta.busco_lineages ? [ meta, assembly ] : [ meta + [ busco_lineages: params.busco_lineages ], assembly ] }
            .flatMap { meta, assembly ->
                meta.busco_lineages instanceof List ?
                    meta.busco_lineages.collect { [ meta, it, assembly.pri_asm ] } :
                    [ [ meta, meta.busco_lineages, assembly.pri_asm ] ]
            }  // Evalute gene space of primary assembly only
            .multiMap { meta, busco_lineage, assembly ->
                fasta_ch: [ meta, assembly ]
                lineage_ch: busco_lineage
            },
        busco_lineage_path,
        []
    )
    versions_ch = BUSCO.out.versions.first()

    emit:
    versions = versions_ch

}
