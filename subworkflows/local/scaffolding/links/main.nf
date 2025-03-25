include { LINKS } from '../../../../modules/local/links/main'
include { QC } from '../../qc/main'
include { RUN_LIFTOFF } from '../../liftoff/main'

workflow RUN_LINKS {
    take:
    inputs
    in_reads
    assembly
    _references
    ch_aln_to_ref
    meryl_kmers

    main:
    Channel.empty().set { ch_versions }

    assembly
        .join(in_reads)
        .set { links_in }

    LINKS(links_in)
    LINKS.out.scaffolds.set { scaffolds }

    ch_versions = ch_versions.mix(LINKS.out.versions)

    QC(inputs, in_reads, scaffolds, ch_aln_to_ref, meryl_kmers)

    ch_versions = ch_versions.mix(QC.out.versions)

    if (params.lift_annotations) {
        RUN_LIFTOFF(scaffolds, inputs)
        ch_versions = ch_versions.mix(RUN_LIFTOFF.out.versions)
    }

    versions = ch_versions

    emit:
    scaffolds
    quast_out               = QC.out.quast_out
    busco_out               = QC.out.busco_out
    merqury_report_files    = QC.out.merqury_report_files
    versions
}
