include { FASTPLONG as FASTPLONG_ONT } from '../../../../modules/nf-core/fastplong/main'
include { COLLECT } from './collect/main'


workflow PREPARE_ONT {
    take:
    ch_main // should contain only samples with ontreads

    main:

    ch_main.dump(tag: "Prepare-ONT input")
    ch_main_collect_branched = ch_main
        .branch {
            it ->
                to_collect: it.meta.ont_collect
                no_collect: !it.meta.ont_collect
        }

    collect_in = ch_main_collect_branched
        .to_collect
        .filter { it -> it.meta.group }
        .map { it -> [it.meta, it.meta.group, it.meta.ontreads] }
        .groupTuple(by: 1)
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
        .mix(
            ch_main_collect_branched
                .to_collect
                .filter { it -> !it.meta.group }
                .map {
                    it -> [ it.meta, it.meta.ontreads ]
                }
        )

    COLLECT(collect_in)

    ch_collected_reads = COLLECT.out.reads
        .filter { it -> it[0].metas }
        .flatMap { it -> // it looks like [meta, output_path]
            it[0].metas
                  .collect { meta -> [ meta: meta - meta.subMap("ontreads") + [ontreads: it[1]] ] }
        }
        .mix(
            COLLECT.out.reads
                .filter { it -> !it[0].metas }
                .map {
                    meta, ontreads -> [ meta: meta - meta.subMap("ontreads") + [ontreads: ontreads] ]
                }
        )

    ch_collected_reads.dump(tag: "Collected ONT reads")

    ch_collected = ch_collected_reads
        .mix(ch_main_collect_branched.no_collect)

    ch_collected.dump(tag: "Collected reads mixed with uncollected.")

    // ch_collected is the same samples as the input channel
    ch_fastplong_in = ch_collected
        .filter { it -> it.meta.group }
        .map { it -> [it.meta, it.meta.group, it.meta.ont_trim, it.meta.ontreads, it.meta.ont_adaptors, it.meta.ont_fastplong_args] }
        .groupTuple(by: 1)
        .map {
            it ->
                [
                    meta: [
                        id: it[1],
                        metas: it[0],
                        trim: it[2][0],
                        ont_fastplong_args: it[5][0]
                        ],
                    ontreads: it[3][0],
                    ont_adaptors: it[4][0]
                ]
        }
        .mix(
            ch_collected
                .filter { it -> !it.meta.group }
                .map {
                    it ->
                    [
                        meta: it.meta,
                        ontreads: it.meta.ontreads,
                        ont_adaptors: it.meta.ont_adaptors,
                    ]
                }
        )
        .multiMap {
            it ->
            reads: [it.meta, it.ontreads]
            adapters: it.ont_adapters ?: []
        }


    FASTPLONG_ONT(ch_fastplong_in.reads, ch_fastplong_in.adapters, false, false)

    fastplong_reads_out = FASTPLONG_ONT
        .out
        .reads
        .filter { it -> it[0].metas }
        .flatMap { it -> // it looks like [meta, output_path]
            it[0].metas
                  .collect { metas -> [ meta: metas - metas.subMap("ontreads") + [ ontreads: it[1] ] ] }
        }
        .mix(FASTPLONG_ONT.out.reads
            .filter { it -> !it[0].metas }
            .map {
                it -> [ meta: it[0] - it[0].subMap("ontreads") + [ ontreads: it[1] ] ]
            }
        )

    fastplong_json_out = FASTPLONG_ONT
        .out
        .json
        .filter { it -> it[0].metas }
        .flatMap { it -> // it looks like [meta, output_path]
            it[0].metas
                  .collect { metas -> [metas, it[1] ] }
        }
        .mix(
            FASTPLONG_ONT.out.json
            .filter { it -> !it[0].metas }
        )

    fastplong_reads_out.dump(tag: "Prepare-ONT output")

    emit:
    main_out = fastplong_reads_out
    fastplong_ont_reports = fastplong_json_out
}
