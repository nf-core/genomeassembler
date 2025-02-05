include { RUN_PILON } from '../run_pilon/main'
include { MAP_SR } from '../../../mapping/map_sr/main'
include { MAP_TO_ASSEMBLY } from '../../../mapping/map_to_assembly/main'
include { RUN_BUSCO } from '../../../qc/busco/main'
include { RUN_QUAST } from '../../../qc/quast/main'
include { RUN_LIFTOFF } from '../../../liftoff/main'
include { MERQURY_QC } from '../../../qc/merqury/main'

workflow POLISH_PILON {
    take:
    ch_input
    shortreads
    in_reads
    assembly
    ch_aln_to_ref
    meryl_kmers

    main:
    Channel.empty().set { quast_out }
    Channel.empty().set { busco_out }
    Channel.empty().set { merqury_report_files }

    MAP_SR(shortreads, assembly)

    RUN_PILON(assembly, MAP_SR.out.aln_to_assembly_bam_bai)

    RUN_PILON.out.set { pilon_polished }

    MAP_TO_ASSEMBLY(in_reads, pilon_polished)

    RUN_QUAST(pilon_polished, ch_input, ch_aln_to_ref, MAP_TO_ASSEMBLY.out.aln_to_assembly_bam)
    RUN_QUAST.out.quast_tsv.set { quast_out }
    RUN_BUSCO(pilon_polished)
    RUN_BUSCO.out.batch_summary.set { busco_out }

    if (params.short_reads) {
        MERQURY_QC(pilon_polished, meryl_kmers)
        MERQURY_QC.out.stats
            .join(
                MERQURY_QC.out.spectra_asm_hist
            )
            .join(
                MERQURY_QC.out.spectra_cn_hist
            )
            .join(
                MERQURY_QC.out.assembly_qv
            )
            .set { merqury_report_files }
    }

    if (params.lift_annotations) {
        RUN_LIFTOFF(pilon_polished, ch_input)
    }

    emit:
    pilon_polished
    quast_out
    busco_out
    merqury_report_files
}
