include { RUN_MEDAKA } from '../run_medaka/main'
include { QC } from '../../../qc/main.nf'
include { RUN_LIFTOFF } from '../../../liftoff/main'

workflow POLISH_MEDAKA {
    take:
    ch_main
    meryl_kmers

    main:
    Channel.empty().set { ch_versions }

    ch_main
        .filter {
            it -> it.polish.medaka
        }
        .multiMap {
            it ->
            reads: [it.meta, it.ontreads]
            reference: [it.meta, it.assembly]
        }
        .set { ch_medaka_in }

    RUN_MEDAKA(ch_medaka_in.reads, ch_medaka_in.reference)

    RUN_MEDAKA.out.medaka_out.set { polished_assembly }

    polished_assembly
        .map { it -> [meta: it[0], polished_medaka: it[1]]}

    ch_main
        .map { it -> it.collect { entry -> [ entry.value, entry ] } }
        .join( polished_assembly
                .map { it -> it.collect {  entry -> [ entry.value, entry ] } }
        )
        // After joining re-create the maps from the stored map
        .map { it -> it.collect { _entry, map -> [ (map.key): map.value ] }.collectEntries() }
        .map { it -> it - it.subMap("polished_medaka") + [polished: [medaka: it.polished.medaka ]]}
        .set { ch_medaka_out }

    ch_main
        .filter { it -> !it.polish_medaka }
        .mix(ch_medaka_out)
        .set { ch_main }

    ch_versions = ch_versions.mix(RUN_MEDAKA.out.versions)

    QC(
        ch_medaka_out.map { it -> it - it.subMap("assembly_map_bam") + [assembly_map_bam: null] },
        polished_assembly,
        meryl_kmers
    )


    ch_versions = ch_versions.mix(QC.out.versions)

    ch_medaka_out
        .filter {
            it -> it.lift_annotations
        }
        .map { it ->
                [
                it.meta,
                it.polished.medaka,
                it.ref_fasta,
                it.ref_gff
                ]
        }
        .set { liftoff_in }

    RUN_LIFTOFF(liftoff_in)

    ch_versions = ch_versions.mix(RUN_LIFTOFF.out.versions)

    versions = ch_versions

    emit:
    ch_main
    quast_out               = QC.out.quast_out
    busco_out               = QC.out.busco_out
    merqury_report_files    = QC.out.merqury_report_files
    versions
}
