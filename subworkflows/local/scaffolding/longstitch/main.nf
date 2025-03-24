include { LONGSTITCH } from '../../../../modules/local/longstitch/main'
include { QC } from '../../qc/main'
include { RUN_LIFTOFF } from '../../liftoff/main'

workflow RUN_LONGSTITCH {
    take:
    inputs
    in_reads
    assembly
    _references
    ch_aln_to_ref
    meryl_kmers
    genome_size

    main:
    Channel.empty().set { ch_versions }

    assembly
        .join(in_reads)
        .join(genome_size)
        .set { longstitch_in }
    LONGSTITCH(longstitch_in)

    LONGSTITCH.out.ntlLinks_arks_scaffolds.set { scaffolds }

    ch_versions = ch_versions.mix(LONGSTITCH.out.versions)

    QC(inputs, in_reads, scaffolds, ch_aln_to_ref, meryl_kmers)

    ch_versions = ch_versions.mix(QC.out.versions)

    if (params.lift_annotations) {
        RUN_LIFTOFF(LONGSTITCH.out.ntlLinks_arks_scaffolds, inputs)
        ch_versions = ch_versions.mix(RUN_LIFTOFF.out.versions)
    }

    versions = ch_versions

    emit:
    scaffolds
    quast_out = QC.out.quast_out
    busco_out = QC.out.busco_out
    merqury_report_files = QC.out.merqury_report_files
    versions
}
