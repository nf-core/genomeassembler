include { RUN_PILON } from '../run_pilon/main'
include { MAP_SR } from '../../../mapping/map_sr/main'
include { RUN_LIFTOFF } from '../../../liftoff/main'
include { QC } from '../../../qc/main.nf'

workflow POLISH_PILON {
    take:
    ch_main
    meryl_kmers

    main:
    Channel.empty().set { ch_versions }

    ch_main.branch {
        it ->
        shortreads: [it.meta, it.shortreads]
        assembly: [
            it.meta,
            it.polish == "medaka+pilon" ? it.polished.medaka : it.assembly
            ]
    }
    .set { map_sr_in }

    MAP_SR(map_sr_in.shortreads, map_sr_in.assembly)

    ch_versions = ch_versions.mix(MAP_SR.out.versions)

    RUN_PILON(map_sr_in.assembly, MAP_SR.out.aln_to_assembly_bam_bai)

    RUN_PILON.out.improved_assembly
        .set { pilon_polished }

    ch_main
        .map { it -> it - it.subMap("polished") + [polished_medaka: it.polished.medaka ?: null] }
        .map { it -> it.collect { entry -> [ entry.value, entry ] } }
        .join(pilon_polished
            .map { it -> [ meta: it[0], polished_pilon: it[1] ] }
            .map { it -> it.collect { entry -> [ entry.value, entry ] } }
        )
        .map { it -> it.collect { _entry, map -> [ (map.key): map.value ] }.collectEntries() }
        .map { it -> (it.polish_medaka ?
                 (it - it.subMap("polished_medaka", "polished_pilon")) :
                 (it - it.subMap("polished_pilon"))) +
                 [polished: [medaka: it.polished_medaka, pilon: it.polished_pilon]]
        }
        .set { ch_main }

    ch_versions = ch_versions.mix(RUN_PILON.out.versions)

    QC(ch_main.map { it -> it - it.submap["assembly_map_bam"]}, pilon_polished, meryl_kmers)

    ch_versions = ch_versions.mix(QC.out.versions)

    ch_main
        .filter {
            it -> it.lift_annotations
        }
        .map { it ->
                [
                it.meta,
                it.polished.pilon,
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
