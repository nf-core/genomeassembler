include { LONGSTITCH } from '../../../../modules/local/longstitch/main'
include { QC } from '../../qc/main'
include { RUN_LIFTOFF } from '../../liftoff/main'

workflow RUN_LONGSTITCH {
    take:
    ch_main
    meryl_kmers

    main:
    Channel.empty().set { ch_versions }

    ch_main
        .map {
            it ->
            [
                it.meta,
                it.polished ? (it.polished.pilon ?: it.polished.medaka) : it.assembly,
                it.qc_reads_path,
                it.genome_size
            ]
        }
        .set { longstitch_in }

    LONGSTITCH(longstitch_in)

    LONGSTITCH.out.ntlLinks_arks_scaffolds
        .set { scaffolds }

    ch_main
        .map { it -> it.collect { entry -> [ entry.value, entry ] } }
        .join(
            scaffolds
                .map { it -> [meta: it[0], scaffolds_longstitch: it[1]] }
                .map { it -> it.collect { entry -> [ entry.value, entry ] } }
        )
        .map { it -> it.collect { _entry, map -> [ (map.key): map.value ] }.collectEntries() }
        .set { ch_main_scaffolded }

    ch_versions = ch_versions.mix(LONGSTITCH.out.versions)

    QC(ch_main_scaffolded.map { it -> it - it.subMap("assembly_map_bam") + [assembly_map_bam: null] }, scaffolds, meryl_kmers)

    ch_versions = ch_versions.mix(QC.out.versions)

    ch_main_scaffolded
        .filter {
            it -> it.lift_annotations
        }
        .map { it ->
                [
                it.meta,
                it.scaffolds_longstitch,
                it.ref_fasta,
                it.ref_gff
                ]
        }
        .set { liftoff_in }

    RUN_LIFTOFF(liftoff_in)
    ch_versions = ch_versions.mix(RUN_LIFTOFF.out.versions)

    emit:
    ch_main
    quast_out               = QC.out.quast_out
    busco_out               = QC.out.busco_out
    merqury_report_files    = QC.out.merqury_report_files
    versions                = ch_versions
}
