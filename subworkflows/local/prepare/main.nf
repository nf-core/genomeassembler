include { PREPARE_ONT as ONT } from './prepare_ont/main'
include { PREPARE_HIFI as HIFI } from './prepare_hifi/main'
include { PREPARE_SHORTREADS as SHORTREADS } from './prepare_shortreads/main'
include { JELLYFISH } from './jellyfish/main'

workflow PREPARE {
    take:
    ch_main

    main:
    ch_main_shortreaded = channel.empty()

    shortreads = ch_main.filter { it ->
        (it.meta.shortread_F && it.meta.use_short_reads) || (it.meta.hic_F && it.meta.scaffold_hic) ? true : false
    }

    ontreads = ch_main.filter { it ->
        it.meta.ontreads ? true : false
    }

    hifireads = ch_main.filter { it ->
        it.meta.hifireads ? true : false
    }

    // adapted to sample-logic

    SHORTREADS(shortreads)

    meryl_kmers = SHORTREADS.out.meryl_kmers

    // This changes ch_main shortreads_F and _R become one tuple, paired is gone.

    // put shortreads back together with samples without shortreads

    // Added mix with empty to make sure that the channel exists
    ch_main_shortreaded = ch_main_shortreaded.mix(
        ch_main.filter { it ->
            !(it.meta.shortread_F && it.meta.use_short_reads) && !(it.meta.hic_trim && it.meta.scaffold_hic)
        }.map { it -> [meta: it.meta - it.meta.subMap("shortread_F", "shortread_R", "paired", "hic_F", "hic_R") + [shortreads: null, hic_reads: null]] }.mix(SHORTREADS.out.main_out)
    )

    ONT(ontreads)

    ch_main_ont_prepped = ONT.out.main_out

    // Continue here with switching to meta

    HIFI(hifireads)

    ch_main_hifi_prepped = HIFI.out.main_out

    ch_main_sr_ont = ch_main_shortreaded
        .filter { it ->
            it.meta.ontreads ? true : false
        }
        .map { it -> [it.meta.id, it.meta - it.meta.subMap("ontreads")] }
        .join(
            ch_main_ont_prepped.map { it -> [it.meta.id, it.meta.ontreads] }
        )
        .map { _id, meta_old, ont_reads ->
            [meta: meta_old - meta_old.subMap("ontreads") + [ontreads: ont_reads]]
        }
        .mix(
            ch_main_shortreaded.filter { it ->
                it.meta.ontreads ? false : true
            }
        )

    // Add prepared hifi-reads:

    ch_main_prepared = ch_main_sr_ont
        .filter { it ->
            it.meta.hifireads ? true : false
        }
        .map { it -> [it.meta.id, it.meta - it.meta.subMap("hifireads")] }
        .join(
            ch_main_hifi_prepped.map { it -> [it.meta.id, it.meta.hifireads] }
        )
        .map { _id, meta_old, hifi_reads ->
            [meta: meta_old + [hifireads: hifi_reads]]
        }
        .mix(
            ch_main_sr_ont.filter { it ->
                it.meta.hifireads ? false : true
            }
        )
        .map { it ->
            [meta: it.meta - it.meta.subMap("qc_reads_path") + [qc_reads_path: it.meta.qc_reads.toLowerCase() == "ont"
                ? it.meta.ontreads
                : it.meta.hifireads]]
        }

    // Get average read length of the QC reads from fastplong json report
    def slurp = new groovy.json.JsonSlurper()

    ch_main_jellyfish_branched = ch_main_prepared
        .filter { it -> it.meta.qc_reads.toLowerCase() == "ont" }
        .map { it ->
            [it.meta.id, it.meta - it.meta.subMap("fastplong_json")]
        }
        .join(
            ONT.out.fastplong_ont_reports.map { it -> [it[0].id, it[1]] }
        )
        .map { _id, meta_old, json ->
            [meta: meta_old + [fastplong_json: json]]
        }
        .mix(
            ch_main_prepared.filter { it -> it.meta.qc_reads.toLowerCase() == "hifi" }.map { it ->
                [it.meta.id, it.meta - it.meta.subMap("fastplong_json")]
            }.join(
                HIFI.out.fastplong_hifi_reports.map { it -> [it[0].id, it[1]] }
            ).map { _id, meta_old, json ->
                [meta: meta_old + [fastplong_json: json]]
            }
        )
        .map { it ->
            [meta: it.meta + [qc_read_mean: slurp.parse(it.meta.fastplong_json).summary.after_filtering.read_mean_length ?: slurp.parse(it.meta.fastplong_json).summary.before_filtering.read_mean_length]]
        }
        .branch { it ->
            jelly: it.meta.jellyfish
            no_jelly: !it.meta.jellyfish
        }

    JELLYFISH(ch_main_jellyfish_branched.jelly)

    main_out = ch_main_jellyfish_branched.no_jelly.mix(JELLYFISH.out.main_out)

    main_out.dump(tag: "Prepare: Combined outputs")

    fastplong_json_reports = HIFI.out.fastplong_hifi_reports.mix(ONT.out.fastplong_ont_reports)

    emit:
    ch_main = main_out
    fastplong_json_reports
    fastp_json_reports = SHORTREADS.out.fastp_json
    meryl_kmers
    genomescope_summary = JELLYFISH.out.genomescope_summary
    genomescope_plot = JELLYFISH.out.genomescope_plot
}
