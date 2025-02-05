include { PILON } from '../../../../../modules/nf-core/pilon/main'

workflow RUN_PILON {
    take:
    assembly_in
    aln_to_assembly_bam_bai

    main:
    assembly_in
        .join(aln_to_assembly_bam_bai)
        .set { pilon_in }
    PILON(
        pilon_in.map { meta, assembly, _bam, _bai -> [meta, assembly] },
        pilon_in.map { meta, _assembly, bam, bai -> [meta, bam, bai] },
        "bam",
    )

    emit:
    PILON.out.improved_assembly
}
