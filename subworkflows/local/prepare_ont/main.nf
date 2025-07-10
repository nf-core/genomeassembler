include { CHOP } from './chop/main'
include { COLLECT } from './collect/main'
include { RUN_NANOQ } from './run_nanoq/main'

workflow PREPARE_ONT {
    take:
    ch_main

    main:
    Channel.empty().set { ch_versions }

    ch_main
        .branch {
            it ->
            ont: it.ontreads != null
            no_ont: !it.ontreads
        }
    .set { ch_ont }

    ch_ont
        .ont
        .branch {
            it ->
            to_collect: it.ont_collect
            no_collect: !it.ont_collect
        }
        .set { ch_ont_collect_branched }

    ch_ont_collect_branched
        .to_collect
        .map { it -> [it.meta, it.ontreads] }
        .set { collect_in }

    COLLECT(collect_in)

    COLLECT.out.reads
        .map { it -> [meta: it[0], ontreads: it[1]] }
        .map { it -> it.collect { entry -> [ entry.value, entry ] } }
        .set { ch_collected_reads }

    ch_ont_collect_branched
        .to_collect
        .map { it -> it - it.subMap["ontreads"] }
        .map { it -> it.collect { entry -> [ entry.value, entry ] } }
        .join(ch_collected_reads)
        .map { it -> it.collect { _entry, map -> [ (map.key): map.value ] }.collectEntries() }
        .mix(ch_ont_collect_branched.no_collect)
        .set { ch_collected }

    ch_collected
        .branch {
            chop: it.ont_trim
            no_chop: !it.ont_trim
        }
        .set { ch_ont_chop_branched }

    ch_ont_chop_branched
            .chop
            .map { it -> [it.meta, it.ontreads]}
            .set { chop_in }

    CHOP(chop_in)

    CHOP.out.chopped_reads
        .join(ch_ont_chop_branched
            .chop
            .map { it -> [it.meta, it.ont_nanoq] }
        )
        .filter { it -> it[2] == true }
        .map { it -> [meta: it[0], ontreads: it[1]]}
        .mix(ch_ont_chop_branched
            .no_chop
            .filter { it -> it.ont_nanoq }
            .map { it -> [meta: it.meta, ontreads: it.ontreads] } )
        .set {ch_nanoq_in}

    RUN_NANOQ(ch_nanoq_in)

    RUN_NANOQ.out.median_length
        .map { it -> [meta: it[0], ont_read_length: it[1]] }
        .map { it -> it.collect { entry -> [ entry.value, entry ] } }
        .set { med_len }

    RUN_NANOQ.out.report.set { nanoq_report }

    RUN_NANOQ.out.stats.set { nanoq_stats }

    ch_ont
        .ont
        .filter { it -> it.ont_nanoq }
        .map { it -> it - it.subMap("ontreads", "ont_read_length") }
        .map { it -> it.collect { entry -> [ entry.value, entry ] } }
        .join( med_len )
        .join( ch_nanoq_in
                .map { it -> it.collect { entry -> [ entry.value, entry ] } }
            )
        .map { it -> it.collect { _entry, map -> [ (map.key): map.value ] }.collectEntries() }
        .mix(ch_ont.no_ont)
        .mix(ch_ont.ont.filter { it -> !it.nanoq })
        .set { main_out }

    versions = ch_versions.mix(COLLECT.out.versions).mix(CHOP.out.versions).mix(RUN_NANOQ.out.versions)

    emit:
    main_out
    nanoq_report
    nanoq_stats
    versions
}
