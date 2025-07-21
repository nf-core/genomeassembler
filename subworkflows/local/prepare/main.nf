include { PREPARE_ONT as ONT } from 'prepare_ont/main'
include { PREPARE_HIFI as HIFI } from 'prepare_hifi/main'
include { PREPARE_SHORTREADS as SHORTREADS } from 'prepare_shortreads/main'

workflow PREPARE {
    take: ch_main

    main:
    ch_main
        .filter {
            it -> (it.shortread_F && it.use_short_reads) ? true : false
        }
        .set { shortreads }

    ch_main
        .filter {
            it -> (it.ontreads) ? true : false
        }
        .set { ontreads }

    ch_main
        .filter {
            it -> (it.hifireads) ? true : false
        }
        .set { hifireads }


    // adapted to sample-logic
    SHORTREADS(shortreads)

    SHORTREADS.out.meryl_kmers.set { meryl_kmers }
    // This changes ch_main shortreads_F and _R become one tuple, paired is gone.

    // put shortreads back together with samples without shortreads

    ch_main
        .filter {
            it -> !it.shortread_F ? true : false
        }
        .map { it -> it - it.subMap("shortread_F","shortread_R", "paired") + [shorteads: null] }
        .mix(SHORTREADS.out.main_out)
        .set { ch_main_shortreaded }


    /*
    TODO:
    A current limitation is that jellyfish / genomescope are only in ONT.
    Further refactoring is probably necessary, PREPARE should be split into shortread
    and longread, and QC-reads should be used to prepare the jellyfish / genomescope

    */
    ONT(ontreads)

    ONT.out.main_out.set { ch_main_ont_prepped }

    ONT.out.nanoq_report.set { nanoq_report }

    ONT.out.nanoq_stats.set { nanoq_stats }

    ONT.out.main_out.set { ch_main_ont_prepped }

    HIFI(hifireads)

    HIFI.out.main_out.set { ch_main_hifi_prepped }

    ch_main_shortreaded
        .filter {
            it -> it.ontreads ? true : false
        }
        .map { it -> it.subMap("meta","shortreads")}
        .map { it -> it.collect { entry -> [ entry.value, entry ] } }
            .join( ch_main_ont_prepped
                    .map { it -> it - it.subMap("shortreads") }
                    .map { it -> it.collect { entry -> [ entry.value, entry ] } }
            )
            // After joining re-create the maps from the stored map
        .map { it -> it.collect { _entry, map -> [ (map.key): map.value ] }.collectEntries() }
        // mix back in those samples where nothing was done to the ont reads
        .mix(ch_main_shortreaded
            .filter {
                it -> it.ontreads ? false : true
            }
        )
        .set {
            ch_main_sr_ont
        }

    // Add prepared hifi-reads:

    ch_main_sr_ont
        .filter {
            it -> it.hifireads ? true : false
        }
        .map { it -> it.subMap("meta","shortreads","ontreads")}
        .map { it -> it.collect { entry -> [ entry.value, entry ] } }
            .join( ch_main_hifi_prepped
                    .map { it -> it - it.subMap("shortreads","ontreads") }
                    .map { it -> it.collect { entry -> [ entry.value, entry ] } }
            )
            // After joining re-create the maps from the stored map
        .map { it -> it.collect { _entry, map -> [ (map.key): map.value ] }.collectEntries() }
        // mix back in those samples where nothing was done to the hifireads reads
        .mix(ch_main_sr_ont
            .filter {
                it -> it.hifireads ? false : true
            }
        )
        .set {
            ch_main_prepared
        }

    ch_main_prepared
        .branch {
            it ->
            jellyfish: it.jellyfish
            no_jelly: !it.jellyfish
        }

    .set { ch_main_jellyfish_branched }

    JELLYFISH(ch_main_jellyfish_branched.jellyfish)

    ch_main_jellyfish_branched.no_jelly
        .mix( JELLYFISH.out.main_out )
        .set { main_out }

    JELLYFISH.out.genomescope_summary.set { genomescope_summary }
    JELLYFISH.out.genomescope_plot.set { genomescope_plot }
    ch_versions = ch_versions.mix(JELLYFISH.out.versions)

    versions = ch_versions
}
