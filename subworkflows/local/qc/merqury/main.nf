include { MERQURY_MERQURY as MERQURY } from '../../../../modules/nf-core/merqury/merqury/main'

workflow MERQURY_QC {
    take:
    assembly
    meryl_out

    main:
    meryl_out
        .map { it -> [[id: it[0].id], it[1]] }
        .join(assembly)
        .set { merqury_in }
    MERQURY(merqury_in)
    MERQURY.out.stats.set { stats }
    MERQURY.out.spectra_asm_hist.set { spectra_asm_hist }
    MERQURY.out.spectra_cn_hist.set { spectra_cn_hist }
    MERQURY.out.assembly_qv.set { assembly_qv }

    emit:
    stats
    spectra_asm_hist
    spectra_cn_hist
    assembly_qv
}
