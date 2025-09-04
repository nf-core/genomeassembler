include { FASTPLONG as FASTPLONG_ONT } from '../../../../modules/nf-core/fastplong/main'
include { COLLECT } from './collect/main'


workflow PREPARE_ONT {
    take:
    ch_main // should contain only samples with ontreads

    main:
    Channel.empty().set { ch_versions }

    ch_main.dump(tag: "Prepare-ONT input")
    ch_main
        .branch {
            it ->
                to_collect: it.ont_collect
                no_collect: !it.ont_collect
        }
        .set { ch_main_collect_branched }

    ch_main_collect_branched
        .to_collect
        .filter { it -> it.group }
        .map { it -> [it.meta, it.group, it.ontreads] }
        .groupTuple(by: 1)
        .map {
            it ->
                [
                    [id: it[1], ids: it[0].id.collect().join("+")],
                    it[2].unique()[0]
                ]
        }
        .mix(
            ch_main_collect_branched
                .to_collect
                .filter { it -> !it.group }
                .map {
                    it -> [ it.meta, it.ontreads ]
                }
        )
        .set { collect_in }

    COLLECT(collect_in)

    COLLECT.out.reads
        .filter { it -> it[0].ids }
        .flatMap { it ->
            it[0].ids
                .tokenize("+")
                .collect { sample -> [ meta: [ id: sample ], ontreads: it[1] ] }
            }
        .mix(COLLECT.out.reads
                .filter { it -> !it[0].ids }
                .map {
                    it -> [ meta: [ it[0].id ], ontreads: it[1] ]
                }
        )
        .map { it -> it.collect { entry -> [ entry.value, entry ] } }
        .set { ch_collected_reads }

    ch_main_collect_branched
        .to_collect
        .map { it -> it - it.subMap("ontreads") }
        .map { it -> it.collect { entry -> [ entry.value, entry ] } }
        .join(ch_collected_reads)
        .map { it -> it.collect { _entry, map -> [ (map.key): map.value ] }.collectEntries() }
        .mix(ch_main_collect_branched.no_collect)
        .set { ch_collected }

    // ch_collected is the same samples as the input channel
    ch_collected
        .filter { it -> it.group }
        .map { it -> [it.meta, it.group, it.ont_trim, it.ontreads, it.ont_adaptors, it.ont_fastplong_args] }
        .groupTuple(by: 1)
        .map {
            it ->
                [
                    meta: [
                        id: it[1], ids: it[0].id.collect().join("+"),
                        trim: it[2].unique()[0],
                        ont_fastplong_args: it[5].unique()[0]
                        ],
                    ontreads: it[3].unique()[0],
                    ont_adaptors: it[4].unique()[0]
                ]
        }
        .mix(
            ch_collected
                .filter { it -> !it.group }
                .map {
                    it ->
                    [
                        meta: [
                            id: it.meta.id,
                            trim: it.ont_trim,
                            ont_fastplong_args: it.ont_fastplong_args
                            ],
                        ontreads: it.ontreads,
                        ont_adaptors: it.ont_adaptors,
                    ]
                }
        )
        .multiMap {
            it ->
            reads: [it.meta, it.ontreads]
            adapters: it.ont_adapters ?: []
        }
        .set { ch_fastplong_in }

    FASTPLONG_ONT(ch_fastplong_in.reads, ch_fastplong_in.adapters, false, false)

    FASTPLONG_ONT
        .out
        .reads
        .filter { it -> it[0].ids }
        .flatMap { it ->
            it[0].ids
                .tokenize("+")
                .collect { sample -> [ meta: [ id: sample ], ontreads: it[1] ] }
            }
        .mix(FASTPLONG_ONT.out.reads
            .filter { it -> !it[0].ids }
            .map {
                it -> [ meta: [ id: it[0].id ], ontreads: it[1] ]
            }
        )
        .set { fastplong_reads_out }

    FASTPLONG_ONT
        .out
        .json
        .filter { it -> it[0].ids }
        .flatMap { it ->
            it[0].ids
                .tokenize("+")
                .collect { sample -> [ [ id: sample ], it[1] ] }
            }
        .mix(FASTPLONG_ONT.out.json
            .filter { it -> !it[0].ids }
            .map {
                it -> [ [ id: it[0].id ], it[1] ]
            }
        )
        .set { fastplong_json_out }

    ch_collected
        .map { it -> it - it.subMap('ontreads') }
        .map { it -> it.collect { entry -> [ entry.value, entry ] } }
        .join(
            fastplong_reads_out
                .map { it -> it.collect { entry -> [ entry.value, entry ] } }
        )
        .map { it -> it.collect { _entry, map -> [ (map.key): map.value ] }.collectEntries() }
        .set { main_out }

    versions = ch_versions.mix(COLLECT.out.versions).mix(FASTPLONG_ONT.out.versions)

    main_out.dump(tag: "Prepare-ONT output")

    emit:
    main_out
    fastplong_ont_reports = fastplong_json_out
    versions
}
