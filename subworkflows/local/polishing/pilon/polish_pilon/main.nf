include { RUN_PILON } from '../run_pilon/main'
include { MAP_SR } from '../../../mapping/map_sr/main'
include { RUN_LIFTOFF } from '../../../liftoff/main'
include { QC } from '../../../qc/main.nf'

workflow POLISH_PILON {
    take:
    ch_input
    shortreads
    in_reads
    assembly
    ch_aln_to_ref
    meryl_kmers

    main:
    Channel.empty().set { ch_versions }

    MAP_SR(shortreads, assembly)

    ch_versions = ch_versions.mix(MAP_SR.out.versions)

    RUN_PILON(assembly, MAP_SR.out.aln_to_assembly_bam_bai)

    RUN_PILON.out.improved_assembly.set { pilon_polished }

    ch_versions = ch_versions.mix(RUN_PILON.out.versions)

    QC(ch_input, in_reads, pilon_polished, ch_aln_to_ref, meryl_kmers)

    ch_versions = ch_versions.mix(QC.out.versions)

    if (params.lift_annotations) {
        RUN_LIFTOFF(pilon_polished, ch_input)
        ch_versions = ch_versions.mix(RUN_LIFTOFF.out.versions)
    }

    versions = ch_versions

    emit:
    pilon_polished
    quast_out               = QC.out.quast_out
    busco_out               = QC.out.busco_out
    merqury_report_files    = QC.out.merqury_report_files
    versions
}
