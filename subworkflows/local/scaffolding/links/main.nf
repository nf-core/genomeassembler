include { LINKS } from '../../../../modules/nf-core/links/main'
include { QC } from '../../qc/main'
include { RUN_LIFTOFF } from '../../liftoff/main'

workflow RUN_LINKS {
    take:
    ch_main
    meryl_kmers

    main:
    Channel.empty().set { ch_versions }

    ch_main
        .multiMap {
            assembly: [it.meta, it.polish.pilon ?: it.polish.medaka ?: it.assembly]
            reads: [it.meta, it.qc_reads]
        }
        .set { links_in }

    LINKS(links_in.assembly, links_in.reads)
    LINKS.out.scaffolds_fasta
        .set { scaffolds }

    ch_main
        .map { it -> it.collect { entry -> [ entry.value, entry ] } }
        .join(
            scaffolds
                .map { it -> [meta: it[0], scaffolds_links: it[1]] }
                .map { it -> it.collect { entry -> [ entry.value, entry ] } }
        )
        .map { it -> it.collect { _entry, map -> [ (map.key): map.value ] }.collectEntries() }
        .set { ch_main }

    ch_versions = ch_versions.mix(LINKS.out.versions)

    QC(ch_main.map { it -> it - it.submap["assembly_map_bam"]}, scaffolds, meryl_kmers)

    ch_versions = ch_versions.mix(QC.out.versions)

    ch_main
        .filter {
            it -> it.lift_annotations
        }
        .map { it ->
                [
                it.meta,
                it.scaffolds_links,
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
