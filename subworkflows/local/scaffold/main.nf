include { RUN_LINKS         } from './links/main'
include { RUN_LONGSTITCH    } from './longstitch/main'
include { RUN_RAGTAG        } from './ragtag/main'
include { HIC               } from './hic/main'

workflow SCAFFOLD {
    take:
    ch_main
    meryl_kmers

    main:
    links_busco = channel.empty()
    links_quast = channel.empty()
    links_merqury = channel.empty()
    longstitch_busco = channel.empty()
    longstitch_quast = channel.empty()
    longstitch_merqury = channel.empty()
    ragtag_busco = channel.empty()
    ragtag_quast = channel.empty()
    ragtag_merqury = channel.empty()

    // There is no support for scaffolding of scaffolded scaffolds.
    // But it is possible that one sample is scaffolded with different tools.
    // Therefore main is filtered, instead of branched.

    links_in = ch_main
        .filter {
            it ->  it.meta.scaffold_links
        }

    RUN_LINKS(links_in, meryl_kmers)
    links_out = RUN_LINKS.out.ch_main

    longstitch_in = ch_main
        .filter {
            it ->  it.meta.scaffold_longstitch
        }

    RUN_LONGSTITCH(longstitch_in, meryl_kmers)

    longstitch_out = RUN_LONGSTITCH.out.ch_main

    hic_in = ch_main
        .filter {
            it ->  it.meta.scaffold_hic
        }

    HIC(hic_in, meryl_kmers)
    hic_out = HIC.out.ch_main

    ragtag_in = ch_main
        .filter {
            it -> it.meta.scaffold_ragtag && !it.meta.hic_reads && !it.meta.scaffold_longstitch && !it.meta.scaffold_links
        }
    .mix(hic_out.filter { it -> it.meta.scaffold_ragtag } )
    .mix(longstitch_out.filter { it -> it.meta.scaffold_ragtag } )
    .mix(links_out.filter { it -> it.meta.scaffold_ragtag } )

    RUN_RAGTAG(ragtag_in, meryl_kmers)
    ragtag_out = RUN_RAGTAG.out.ch_main

    // Deal with cases that are single scaffold
    ch_main = links_out
        .filter {it -> !it.meta.scaffold_longstitch && !it.meta.scaffold_ragtag }
        .map { meta -> [ meta: meta - meta.subMap("links_scaffold") + [ scaffolds: [ links: meta.scaffolds_links ] ]  ]}
        .mix(
            longstitch_out
                .filter {it -> !it.meta.scaffold_links && !it.meta.scaffold_ragtag }
                .map { meta -> [ meta: meta - meta.subMap("scaffolds_longstitch") + [ scaffolds: [ longstitch: meta.scaffolds_longstitch ] ]  ]}
        )
        .mix(
            ragtag_out
                .filter {it -> !it.meta.scaffold_links && !it.meta.scaffold_longstitch }
                .map { meta -> [ meta: meta - meta.subMap("scaffolds_ragtag") + [ scaffolds: [ ragtag: meta.scaffolds_ragtag ] ]  ]}
        )
        .mix(
            hic_out
                .map { meta -> [ meta: meta - meta.subMap("scaffolds_hic") + [ scaffolds: [ hic: meta.scaffolds_hic ] ]  ]}

            )
        // mix in those that are double scaffolded: , links-ragtag, longstitch-ragtag
        // links-longstitch
        .mix(
            links_out
                .filter {it -> it.meta.scaffold_longstitch && !it.meta.scaffold_ragtag }
                .map {meta -> [meta.id, meta]}
                // Join without filtering, inner-join
                .join(
                    longstitch_out
                        .map {meta -> [meta.id, meta]}
                )
                .map {
                    _id, meta_links, meta_longstitch -> [
                        meta: meta_links -
                         meta_links.subMap("scaffolds_links") +
                         [scaffolds: [links: meta_links.scaffolds_links, longstitch: meta_longstitch.scaffolds_longstitch]] ]
                }
        )
        //links-ragtag
        .mix(
            links_out
                .filter {it -> !it.meta.scaffold_longstitch && it.meta.scaffold_ragtag }
                .map {meta -> [meta.id, meta]}
                // Join without filtering, inner-join
                .join(
                    ragtag_out
                        .map {meta -> [meta.id, meta]}
                )
                .map {
                    _id, meta_links, meta_ragtag -> [
                        meta: meta_links -
                         meta_links.subMap("scaffolds_links") +
                         [scaffolds: [links: meta_links.scaffolds_links, ragtag: meta_ragtag.scaffolds_ragtag]] ]
                }
        )
        //longstitch-ragtag
        .mix(
            longstitch_out
                .filter {it -> !it.meta.scaffold_links && it.meta.scaffold_ragtag }
                .map {meta -> [meta.id, meta]}
                // Join without filtering, inner-join
                .join(
                    ragtag_out
                        .map {meta -> [meta.id, meta]}
                )
                .map {
                    _id, meta_longstitch, meta_ragtag -> [
                        meta: meta_longstitch -
                         meta_longstitch.subMap("scaffolds_longstitch") +
                         [scaffolds: [longstitch: meta_longstitch.scaffolds_longstitch, ragtag: meta_ragtag.scaffolds_ragtag]] ]
                }
        )
        // mix in triple-scaffolded
        .mix(
            links_out
                .filter {it -> it.meta.scaffold_longstitch && it.meta.scaffold_ragtag }
                .map {meta -> [meta.id, meta]}
                // Join without filtering, inner-join
                .join(
                    longstitch_out
                        .map {meta -> [meta.id, meta]}
                )
                .join(
                    ragtag_out
                        .map {meta -> [meta.id, meta]}
                )
                .map {
                    _id, meta_links, meta_longstitch, meta_ragtag -> [
                        meta: meta_links -
                         meta_links.subMap("scaffolds_links") +
                            [
                                scaffolds: [
                                links: meta_links.scaffolds_links,
                                longstitch: meta_longstitch.scaffolds_longstitch,
                                ragtag: meta_ragtag.scaffolds_ragtag
                                ]
                            ]
                             ]
                }
        )


    links_busco = RUN_LINKS.out.busco_out
    links_quast = RUN_LINKS.out.quast_out
    links_merqury = RUN_LINKS.out.merqury_report_files

    longstitch_busco = RUN_LONGSTITCH.out.busco_out
    longstitch_quast = RUN_LONGSTITCH.out.quast_out
    longstitch_merqury = RUN_LONGSTITCH.out.merqury_report_files

    hic_busco = HIC.out.busco_out
    hic_quast = HIC.out.quast_out
    hic_merqury = HIC.out.merqury_report_files

    ragtag_busco = RUN_RAGTAG.out.busco_out
    ragtag_quast = RUN_RAGTAG.out.quast_out
    ragtag_merqury = RUN_RAGTAG.out.merqury_report_files

    scaffold_busco_reports = links_busco
        .concat(longstitch_busco)
        .concat(ragtag_busco)
        .concat(hic_busco)

    scaffold_quast_reports = links_quast
        .concat(longstitch_quast)
        .concat(ragtag_quast)
        .concat(hic_quast)

    scaffold_merqury_reports = links_merqury
        .concat(longstitch_merqury)
        .concat(ragtag_merqury)
        .concat(hic_merqury)

    emit:
    ch_main
    scaffold_busco_reports
    scaffold_quast_reports
    scaffold_merqury_reports
}
