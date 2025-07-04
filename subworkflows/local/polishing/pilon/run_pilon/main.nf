include { PILON } from '../../../../../modules/nf-core/pilon/main'

workflow RUN_PILON {
    take:
    assembly_in
    aln_to_assembly_bam_bai

    main:

    assembly_in
        .join(aln_to_assembly_bam_bai)
        .multiMap {
            meta, assembly, bam, bai ->
            assembly: [meta, assembly]
            bam_bai: [meta, bam, bai]
        }
        .set { pilon_in }

    PILON(
        pilon_in.assembly,
        pilon_in.bam_bai,
        "bam",
    )
    versions = PILON.out.versions

    improved_assembly = PILON.out.improved_assembly

    emit:
    improved_assembly
    versions
}
