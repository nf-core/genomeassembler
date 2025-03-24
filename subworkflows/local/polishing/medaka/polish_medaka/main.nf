include { RUN_MEDAKA } from '../run_medaka/main'
include { QC } from '../../../qc/main.nf'
include { RUN_LIFTOFF } from '../../../liftoff/main'

workflow POLISH_MEDAKA {
    take:
    ch_input
    in_reads
    assembly
    ch_aln_to_ref
    meryl_kmers

    main:
    Channel.empty().set { ch_versions }
    Channel.empty().set { quast_out }
    Channel.empty().set { busco_out }
    Channel.empty().set { merqury_report_files }

    RUN_MEDAKA(in_reads, assembly)
    RUN_MEDAKA.out.medaka_out.set { polished_assembly }

    ch_versions = ch_versions.mix(RUN_MEDAKA.out.versions)

    QC(ch_input, in_reads, polished_assembly, ch_aln_to_ref, meryl_kmers)

    ch_versions = ch_versions.mix(QC.out.versions)

    if (params.lift_annotations) {
        RUN_LIFTOFF(polished_assembly, ch_input)
        ch_versions = ch_versions.mix(RUN_LIFTOFF.out.versions)
    }

    versions = ch_versions

    emit:
    polished_assembly
    quast_out = QC.out.quast_out
    busco_out = QC.out.busco_out
    merqury_report_files = QC.out.merqury_report_files
    versions
}
