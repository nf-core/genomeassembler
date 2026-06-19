include { PILON } from '../../../../../modules/nf-core/pilon/main'

workflow RUN_PILON {
    take:
    assembly_in
    aln_to_assembly_bam_csi

    main:
    assembly_in
        .join(aln_to_assembly_bam_csi)
        .set { pilon_in }
    PILON(
        pilon_in.map { meta, assembly, _bam, _csi -> [meta, assembly] },
        pilon_in.map { meta, _assembly, bam, csi -> [meta, bam, csi] },
        "bam",
    )
    versions = PILON.out.versions
    improved_assembly = PILON.out.improved_assembly

    emit:
    improved_assembly
    versions
}
