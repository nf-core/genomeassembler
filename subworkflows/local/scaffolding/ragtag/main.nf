include { RAGTAG_SCAFFOLD } from '../../../../modules/nf-core/ragtag/scaffold/main'
include { QC } from '../../qc/main'
include { RUN_LIFTOFF } from '../../liftoff/main'


workflow RUN_RAGTAG {
    take:
    inputs
    in_reads
    assembly
    references
    ch_aln_to_ref
    meryl_kmers

    main:
    Channel.empty().set { ch_versions }

    assembly
        .join(references)
        .multiMap { meta, assembly_fasta, reference_fasta ->
                    assembly: [meta, assembly_fasta]
                    reference: [meta, reference_fasta]
                    }
        .set { ragtag_in }

    RAGTAG_SCAFFOLD(ragtag_in.assembly, ragtag_in.reference, [[], []], [[], [], []])

    RAGTAG_SCAFFOLD.out.corrected_assembly.set { ragtag_scaffold_fasta }

    RAGTAG_SCAFFOLD.out.corrected_agp.set { ragtag_scaffold_agp }

    ch_versions = ch_versions.mix(RAGTAG_SCAFFOLD.out.versions)

    QC(inputs, in_reads, ragtag_scaffold_fasta, ch_aln_to_ref, meryl_kmers)

    ch_versions = ch_versions.mix(QC.out.versions)

    if (params.lift_annotations) {
        RUN_LIFTOFF(RAGTAG_SCAFFOLD.out.corrected_assembly, inputs)
        ch_versions = ch_versions.mix(RUN_LIFTOFF.out.versions)
    }

    versions = ch_versions

    emit:
    ragtag_scaffold_fasta
    ragtag_scaffold_agp
    quast_out               = QC.out.quast_out
    busco_out               = QC.out.busco_out
    merqury_report_files    = QC.out.merqury_report_files
    versions
}
