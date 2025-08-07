include { PREPARE_ONT as ONT } from './prepare_ont/main'
include { PREPARE_HIFI as HIFI } from './prepare_hifi/main'
include { PREPARE_SHORTREADS as SHORTREADS } from './prepare_shortreads/main'
include { JELLYFISH } from './jellyfish/main'

workflow PREPARE {
    // TODO: Switch to fastp and fastplong.

    /*
                        Grouped preparations

    Generally, I expect that a group will contain the same set of input.
    To reduce redundant work on the inputs that belong one group, in all
    prepare_* subworkflows groups will be used as meta.id, if a group is
    set. After the preparations are done, results are joined back to all
    members of the group. This needs to account for sample level setting
    of additional args. For preparation no arg can be set at the sample-
    level, so here everything group only.

    The pattern for grouping/ungrouping and mixing samples is:

    Grouping:
    channel_grouped is a map that contains at least meta, group and path
    within one group the path is expected to be the same for all members

    channel_grouped
        .filter { it -> it.group  }
        .map { it -> [it.meta, it.group, it.path] }
        .groupTuple(by: 1)
        .map {
            it ->
                [
                    [id: it[1], ids: it[0].id.collect().join("+")],
                    it[2].unique()[0]
                ]
        }
        .mix(
            groups
                .filter { it -> !it.group }
                .map {
                    it -> [ it.meta, it.path ]
                }
        )
        .set { collected_groups }

    This produces one channel that contains meta and path ready to go in
    a process.

    For a process that again returns [meta, path] split group in samples
    and merge with ungrouped samples:

    PROCESS(collected_groups)

    PROCESS.out
        .filter { it -> it[0].ids }
        .flatMap { it ->
            it[0].ids
                .tokenize("+")
                .collect { sample -> [ meta: [ id: sample ], path: it[1] ] }
            }
        .mix(PROCESS.out
            .filter { it -> !it[0].ids }
            .map {
                it -> [ meta: [ id: it[0].id ], path: it[1] ]
            }
        )
        .set { process_output }
    */

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


    ONT(ontreads)

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
        .map { it -> it.subMap("meta", "shortreads", "ontreads")}
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

    // Get average read length of the QC reads from fastplong json report
    def slurp = new groovy.json.JsonSlurper()

    ch_main_prepared
        .filter(it.qc_reads.toLower() == "ont")
        .map { it -> it.collect { entry -> [ entry.value, entry ] } }
        .join(ONT.out.fastplong_ont_reports
                .map { it -> [ meta: it[0], fastplong_json: it[1] ]}
                .map { it -> it.collect { entry -> [ entry.value, entry ] } }
            )
        .mix(
            ch_main_prepared
            .filter(it.qc_reads.toLower() == "hifi")
            .map { it -> it.collect { entry -> [ entry.value, entry ] } }
            .join(HIFI.out.fastplong_hifi_reports
                .map { it -> [ meta: it[0], fastplong_json: it[1] ]}
                .map { it -> it.collect { entry -> [ entry.value, entry ] } }
            )
        )
        .map { it -> it.collect { _entry, map -> [ (map.key): map.value ] }.collectEntries() }
        .map { it ->
            it +
            [
                qc_read_mean: slurp.parse(it.fastplong_json).summary.after_filtering.read_mean_length ?:
                              slurp.parse(it.fastplong_json).summary.before_filtering.read_mean_length
            ] -
            it.subMap("fastplong_json")
        }
        .branch {
            it ->
                jelly: it.jellyfish
                no_jelly: !it.jellyfish
        }
        .set { ch_main_jellyfish_branched }



    JELLYFISH(ch_main_jellyfish_branched.jelly)

    ch_main_jellyfish_branched.no_jelly
        .mix( JELLYFISH.out.main_out )
        .set { main_out }

    JELLYFISH.out.genomescope_summary.set { genomescope_summary }
    JELLYFISH.out.genomescope_plot.set { genomescope_plot }

    SHORTREADS.out.versions
        .mix(ONT.out.versions)
        .mix(HIFI.out.versions)
        .mix(JELLYFISH.out.versions)
        .set { versions }

    fastplong_json_reports = HIFI.out.fastplong_hifi_reports.mix(ONT.out.fastplong_ont_reports)

    emit:
    ch_main                 = main_out
    fastplong_json_reports
    meryl_kmers
    genomescope_summary
    genomescope_plot
    versions
}
