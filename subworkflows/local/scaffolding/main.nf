include { RUN_LINKS } from './links/main'
include { RUN_LONGSTITCH } from './longstitch/main'
include { RUN_RAGTAG } from './ragtag/main'

workflow SCAFFOLD {
    take:
    ch_main
    meryl_kmers

    main:
    Channel.empty().set { ch_versions }
    Channel.empty().set { links_busco }
    Channel.empty().set { links_quast }
    Channel.empty().set { links_merqury }
    Channel.empty().set { longstitch_busco }
    Channel.empty().set { longstitch_quast }
    Channel.empty().set { longstitch_merqury }
    Channel.empty().set { ragtag_busco }
    Channel.empty().set { ragtag_quast }
    Channel.empty().set { ragtag_merqury }

    // There is no support for scaffolding of scaffolded scaffolds.
    // But it is possible that one sample is scaffolded with different tools.
    // Therefore main is filtered, instead of branched.


    ch_main
        .filter {
            it ->  it.scaffold_links
        }
    .set { links_in }

    RUN_LINKS(links_in, meryl_kmers)

    RUN_LINKS.out.ch_main
        .map { it -> it.subMap("meta", "scaffolds_links")}
        .map { it -> it.collect { entry -> [ entry.value, entry ] } }
        .set { links_out }

    ch_main
        .filter {
            it ->  it.scaffold_longstitch
        }
    .set { longstitch_in }

    RUN_LONGSTITCH(longstitch_in, meryl_kmers)
    RUN_LONGSTITCH.out.ch_main
        .map { it -> it.subMap("meta", "scaffolds_longstitch")}
        .map { it -> it.collect { entry -> [ entry.value, entry ] } }
        .set { longstitch_out }

    ch_main
        .filter {
            it ->  it.scaffold_ragag
        }
    .set { ragtag_in }

    RUN_RAGTAG(ragtag_in, meryl_kmers)
    RUN_RAGTAG.out.ch_main
        .map { it -> it.subMap("meta","scaffolds_ragtag")}
        .map { it -> it.collect { entry -> [ entry.value, entry ] } }
        .set { ragtag_out }

    ch_main
        .map { it -> it.collect { entry -> [ entry.value, entry ] } }
        .join(links_out)
        .join(longstitch_out)
        .join(ragtag_out)
        .map { it -> it.collect { _entry, map -> [ (map.key): map.value ] }.collectEntries() }
        .map {
            it -> it - it.subMap("scaffolds_links","scaffolds_longstitch", "scaffolds_ragtag") +
            [
                scaffolds: [
                    links: it.scaffold_links ?: null,
                    longstitch: it.scaffold_longstitch ?: null,
                    ragtag: it.scaffolds_ragtag ?: null
                ]
            ]
        }
        .set { ch_main }


    RUN_LINKS.out.busco_out.set { links_busco }
    RUN_LINKS.out.quast_out.set { links_quast }
    RUN_LINKS.out.merqury_report_files.set { links_merqury }

    ch_versions = ch_versions.mix(RUN_LINKS.out.versions)

    RUN_LONGSTITCH.out.busco_out.set { longstitch_busco }
    RUN_LONGSTITCH.out.quast_out.set { longstitch_quast }
    RUN_LONGSTITCH.out.merqury_report_files.set { longstitch_merqury }
    ch_versions = ch_versions.mix(RUN_LONGSTITCH.out.versions)

    RUN_RAGTAG.out.busco_out.set { ragtag_busco }
    RUN_RAGTAG.out.quast_out.set { ragtag_quast }
    RUN_RAGTAG.out.merqury_report_files.set { ragtag_merqury }

    ch_versions = ch_versions.mix(RUN_RAGTAG.out.versions)

    links_busco
        .concat(longstitch_busco)
        .concat(ragtag_busco)
        .set { scaffold_busco_reports }

    links_quast
        .concat(longstitch_quast)
        .concat(ragtag_quast)
        .set { scaffold_quast_reports }

    links_merqury
        .concat(longstitch_merqury)
        .concat(ragtag_merqury)
        .set { scaffold_merqury_reports }

    versions = ch_versions

    emit:
    ch_main
    scaffold_busco_reports
    scaffold_quast_reports
    scaffold_merqury_reports
    versions
}
