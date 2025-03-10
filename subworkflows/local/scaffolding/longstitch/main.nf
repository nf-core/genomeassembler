include { LONGSTITCH } from '../../../../modules/local/longstitch/main'
include { MAP_TO_ASSEMBLY } from '../../mapping/map_to_assembly/main'
include { RUN_QUAST } from '../../qc/quast/main'
include { RUN_BUSCO } from '../../qc/busco/main'
include { RUN_LIFTOFF } from '../../liftoff/main'
include { MERQURY_QC } from '../../qc/merqury/main'

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
    Channel.empty().set { quast_out }
    Channel.empty().set { busco_out }
    Channel.empty().set { merqury_report_files }
    assembly
        .join(in_reads)
        .join(genome_size)
        .set { longstitch_in }
    LONGSTITCH(longstitch_in)

    LONGSTITCH.out.ntlLinks_arks_scaffolds.set { scaffolds }

    ch_versions = ch_versions.mix(LONGSTITCH.out.versions)

    MAP_TO_ASSEMBLY(in_reads, scaffolds)

    ch_versions = ch_versions.mix(MAP_TO_ASSEMBLY.out.versions)

    RUN_QUAST(scaffolds, inputs, ch_aln_to_ref, MAP_TO_ASSEMBLY.out.aln_to_assembly_bam)
    RUN_QUAST.out.quast_tsv.set { quast_out }

    ch_versions = ch_versions.mix(RUN_QUAST.out.versions)

    RUN_BUSCO(scaffolds)
    RUN_BUSCO.out.batch_summary.set { busco_out }

    ch_versions = ch_versions.mix(RUN_BUSCO.out.versions)

    if (params.short_reads) {
        MERQURY_QC(scaffolds, meryl_kmers)
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

        ch_versions = ch_versions.mix(MERQURY_QC.out.versions)
    }
    if (params.lift_annotations) {
        RUN_LIFTOFF(LONGSTITCH.out.ntlLinks_arks_scaffolds, inputs)
        ch_versions = ch_versions.mix(RUN_LIFTOFF.out.versions)
    }

    versions = ch_versions

    emit:
    scaffolds
    quast_out
    busco_out
    merqury_report_files
    versions
}
