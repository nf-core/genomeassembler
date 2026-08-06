include { PREPARE_ONT as ONT } from './prepare_ont/main'
include { PREPARE_HIFI as HIFI } from './prepare_hifi/main'
include { PREPARE_SHORTREADS as SHORTREADS } from './prepare_shortreads/main'
include { JELLYFISH } from './jellyfish/main'

workflow PREPARE {
    /*
    Subworkflows in prepare implement sample grouping.
    SHORTREADS, JELLYFISH, ONT and HIFI each implement
    the same logic for sample grouping.
    Grouping needs to be specified by the user, and can
    be used to create sample groups that share inputs, to
    minimize redundant input preparations.
    Reads of samples from the same group will be prepared
    only once, and then the original channel is restored.

    Brief description how this works:
        // Move group information into channel, if it exists
        .filter { it -> it.meta.group }
        .map { it -> [it.meta, it.meta.group, it.meta.ontreads] }
        // Group by group
        .groupTuple(by: 1)
        // Collect all sample-meta into a group meta slot named metas
        // Use unique reads; user responsible to group correctly
        .map {
            it ->
                [
                    [
                        id: it[1], // the group
                        metas: it[0]
                    ],
                    it[2].unique()[0] // Ontreads
                ]
        }

    After this input channel has been processed, the samples are
    recreated from meta[metas]:

    process.OUT
        // Take samples with metas in slot [0]
        .filter { it -> it[0].metas }
        .flatMap { it ->
            // $it looks like [meta, output_path]
            // recreate meta from metas and update path.
            it[0].metas
                  .collect { meta -> [
                                meta: meta - meta.subMap("ontreads") + [ontreads: it[1]]
                                ]
                            }
        }
        .mix(
            process.OUT
                .filter { it -> !it[0].metas }
                .map {meta, ontreads -> [meta: meta -meta.subMap("ontreads") + [ontreads: ontreads]]}
        )


    */
    take: ch_main

    main:
    ch_main_shortreaded = channel.empty()

    shortreads = ch_main
        .filter {
            it -> ((it.meta.shortread_F && it.meta.use_short_reads) || it.hic_trim) ? true : false
        }

    ontreads = ch_main
        .filter {
            it -> (it.meta.ontreads) ? true : false
        }

    hifireads = ch_main
        .filter {
            it -> (it.meta.hifireads) ? true : false
        }

    // adapted to sample-logic

    SHORTREADS(shortreads)

    meryl_kmers = SHORTREADS.out.meryl_kmers

    // This changes ch_main shortreads_F and _R become one tuple, paired is gone.

    // put shortreads back together with samples without shortreads

    // Added mix with empty to make sure that the channel exists
    ch_main_shortreaded = ch_main_shortreaded
        .mix(
            ch_main
                .filter {
                    it -> !it.meta.shortread_F && !it.meta.hic_F
                }
                .map { it -> [meta: it.meta - it.meta.subMap("shortread_F","shortread_R", "paired") + [shorteads: null] ]}
                .mix(SHORTREADS.out.main_out)
        )

    ONT(ontreads)

    ch_main_ont_prepped = ONT.out.main_out

    // Continue here with switching to meta

    HIFI(hifireads)

    ch_main_hifi_prepped = HIFI.out.main_out

    ch_main_sr_ont = ch_main_shortreaded
        // ADD ONT READS
        .filter {
            it -> it.meta.ontreads ? true : false
        }
        .map { it -> [it.meta.id, it.meta - it.meta.subMap("ontreads")]}
        .join(
            ch_main_ont_prepped
                .map { it -> [it.meta.id, it.meta.ontreads] }
            )
        // After joining re-create the maps from the stored map
        .map { _id, meta_old, ont_reads ->
            [
                meta: meta_old -meta_old.subMap("ontreads") + [ontreads: ont_reads]
            ]
        }
        // mix back in those samples where nothing was done to the ont reads
        .mix(ch_main_shortreaded
            .filter {
                it -> it.meta.ontreads ? false : true
            }
        )

    // Add prepared hifi-reads:

    ch_main_prepared = ch_main_sr_ont
        .filter {
            it -> it.meta.hifireads ? true : false
        }
        .map { it -> [it.meta.id, it.meta - it.meta.subMap("hifireads")]}
        .join(
            ch_main_hifi_prepped
                .map { it -> [it.meta.id, it.meta.hifireads] }
            )
            // After joining re-create the maps from the stored map
        .map { _id, meta_old, hifi_reads ->
            [
                meta: meta_old + [hifireads: hifi_reads]
            ]
        }
        // mix back in those samples where nothing was done to the hifireads reads
        .mix(ch_main_sr_ont
            .filter {
                it -> it.meta.hifireads ? false : true
            }
        )

    // Get average read length of the QC reads from fastplong json report
    def slurp = new groovy.json.JsonSlurper()

    ch_main_jellyfish_branched = ch_main_prepared
        .filter { it -> it.meta.qc_reads.toLowerCase() == "ont" }
        .map { it ->
            [
                it.meta.id,
                it.meta - it.meta.subMap("fastplong_json")
            ]
        }
        .join(
            ONT.out.fastplong_ont_reports
                .map { it -> [ it[0].id, it[1] ]}
        )
        .map {
            _id, meta_old, json -> [meta: meta_old + [fastplong_json: json]]
        }
        .mix(
            ch_main_prepared
            .filter { it -> it.meta.qc_reads.toLowerCase() == "hifi" }
            .map {
                it -> [
                    it.meta.id, it.meta - it.meta.subMap("fastplong_json")]}
            .join(
                HIFI.out.fastplong_hifi_reports
                    .map { it -> [ it[0].id, it[1] ]}
            )
            .map {
            _id, meta_old, json -> [meta: meta_old + [fastplong_json: json]]
            }
        )
        .map { it ->
            [
                meta: it.meta +
                    [
                        qc_read_mean: slurp.parse(it.meta.fastplong_json)
                            .summary
                            .after_filtering
                            .read_mean_length ?:
                        slurp.parse(it.meta.fastplong_json)
                            .summary
                            .before_filtering
                            .read_mean_length
                    ]
            ]
        }
        // branch this channel for jellyfish
        .branch {
            it ->
                jelly: it.meta.jellyfish
                no_jelly: !it.meta.jellyfish
        }

    JELLYFISH(ch_main_jellyfish_branched.jelly)

    main_out = ch_main_jellyfish_branched.no_jelly
        .mix( JELLYFISH.out.main_out )
        // At this stage, make sure that qc_read_path for downstream qc is using the prepared reads.
        .map { it ->
            [
                meta:   it.meta -
                        it.meta.subMap("qc_read_path") +
                        [
                            qc_read_path: it.meta.qc_reads.toLowerCase() == "ont" ?
                            it.meta.ontreads :
                            it.meta.hifireads
                        ]
            ]
        }

    main_out.dump(tag: "Prepare: Combined outputs")

    genomescope_summary = JELLYFISH.out.genomescope_summary

    genomescope_plot = JELLYFISH.out.genomescope_plot

    fastplong_json_reports = HIFI.out.fastplong_hifi_reports.mix(ONT.out.fastplong_ont_reports)

    emit:
    ch_main                 = main_out
    fastplong_json_reports
    fastp_json_reports      = SHORTREADS.out.fastp_json
    meryl_kmers
    genomescope_summary
    genomescope_plot
}
