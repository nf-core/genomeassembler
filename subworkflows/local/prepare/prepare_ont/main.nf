include { FASTPLONG          } from '../../../../modules/nf-core/fastplong/main'
include { CHOPPER            } from '../../../../modules/nf-core/chopper/main'
include { COLLECT            } from './collect/main'


workflow PREPARE_ONT {
    take:
    ch_main // should contain only samples with ontreads

    main:

    ch_main.dump(tag: "Prepare-ONT input")

    // -------------------------------------------------------------------------
    // COLLECT ONT READS
    // -------------------------------------------------------------------------
    
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

    ch_collected = ch_collected_reads
        .mix(ch_main_collect_branched.no_collect)

    ch_collected.dump(tag: "Collected reads mixed with uncollected.")

    // -------------------------------------------------------------------------
    // FASTPLONG
    // -------------------------------------------------------------------------

    // ch_collected is the same samples as the input channel
    ch_fastplong_in = prepareReadsAndAdapters(
        ch_collected.filter { it -> it.meta.trimmer == 'fastplong' }
    )

    ch_fastplong_in.reads.dump(tag: "Fastplong ONT reads in", pretty: true)

    FASTPLONG(ch_fastplong_in.reads, ch_fastplong_in.adapters, false, false)

    // processing filtered reads
    fastplong_reads_out = processFilteredReads(FASTPLONG.out.reads)

    // processing json report
    ch_fastplong_out_json  = FASTPLONG.out.json
    fastplong_json_out = ch_fastplong_out_json
        .filter { it -> it[0].metas }
        .flatMap { it -> // it looks like [meta, output_path]
            it[0].metas
                  .collect { metas -> [metas, it[1] ] }
        }
        .mix(
            ch_fastplong_out_json
            .filter { it -> !it[0].metas }
        )

    fastplong_reads_out.dump(tag: "Prepare-ONT fastplong output", pretty: true)

    // -------------------------------------------------------------------------
    // CHOPPER
    // -------------------------------------------------------------------------

    ch_chopper_in = prepareReadsAndAdapters(
        ch_collected.filter { it -> it.meta.trimmer == 'chopper' }
    )

    ch_chopper_in.reads.dump(tag: "Chopper ONT reads in")

    CHOPPER(ch_chopper_in.reads, ch_chopper_in.adapters)

    // processing filtered reads
    chopper_reads_out = processFilteredReads(CHOPPER.out.fastq)

    chopper_reads_out.dump(tag: "Prepare-ONT chopper output", pretty: true)


    ch_filtered_reads = fastplong_reads_out.mix( chopper_reads_out )

    emit:
    main_out = fastplong_reads_out
    fastplong_ont_reports = fastplong_json_out
}



def prepareReadsAndAdapters(ch_in) {
    return ch_in
            .filter { it -> it.meta.group }
            .map { it -> [it.meta, it.meta.group, it.meta.ont_trim, it.meta.ontreads, it.meta.ont_adaptors, it.meta.trimmer_ont_args] }
            .groupTuple(by: 1)
            .map {
                it ->
                    [
                        meta: [
                            id: it[1],
                            metas: it[0],
                            trim: it[2][0],
                            trimmer_ont_args: it[5][0]
                            ],
                        ontreads: it[3][0],
                        ont_adaptors: it[4][0]
                    ]
            }
            .mix(
                ch_in
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
}


def processFilteredReads(ch_reads) {
    return ch_reads
        .filter { it -> it[0].metas }
        .flatMap { it -> // it looks like [meta, output_path]
            it[0].metas
                  .collect { metas -> [ meta: metas - metas.subMap("ontreads") + [ ontreads: it[1] ] ] }
        }
        .mix(ch_reads
            .filter { it -> !it[0].metas }
            .map {
                it -> [ meta: it[0] - it[0].subMap("ontreads") + [ ontreads: it[1] ] ]
            }
        )
}