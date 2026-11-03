include { FASTPLONG          } from '../../../../modules/nf-core/fastplong/main'
include { CHOPPER            } from '../../../../modules/nf-core/chopper/main'

workflow PREPARE_HIFI {
    take:
    main_in // should contain only samples with hifireads

    main:

    main_in.dump(tag: "Prepare-HIFI input")

    // -------------------------------------------------------------------------
    // FASTPLONG
    // -------------------------------------------------------------------------

    ch_fastplong_in = prepareReadsAndAdapters(
        main_in.filter { it -> it.meta.trimmer == 'fastplong' }
    )

    ch_fastplong_in.reads.dump(tag: "Fastplong HIFI reads in")
    
    FASTPLONG(ch_fastplong_in.reads, ch_fastplong_in.adapters, false, false )

    // processing filtered reads
    fastplong_reads_out = processFilteredReads(FASTPLONG.out.reads)

    fastplong_reads_out.dump(tag: "Prepare-HIFI fastplong output")

    // processing json report
    ch_fastplong_out_json  = FASTPLONG.out.json
    fastplong_json_out = ch_fastplong_out_json
        .filter { it -> it[0].metas }
        .flatMap { it ->
            it[0].metas
                .collect { meta -> [ meta, it[1] ] }
            }
        .mix(ch_fastplong_out_json
            .filter { it -> !it[0].metas }
        )

    // -------------------------------------------------------------------------
    // CHOPPER
    // -------------------------------------------------------------------------

    ch_chopper_in = prepareReadsAndAdapters(
        main_in.filter { it -> it.meta.trimmer == 'chopper' }
    )

    ch_chopper_in.reads.dump(tag: "Chopper HIFI reads in")

    CHOPPER(ch_chopper_in.reads, ch_trimmer_in.adapters)

    // processing filtered reads
    chopper_reads_out = processFilteredReads(CHOPPER.out.fastq)

    chopper_reads_out.dump(tag: "Prepare-HIFI chopper output")


    ch_filtered_reads = fastplong_reads_out.mix( chopper_reads_out )
    
    emit:
    main_out                = ch_filtered_reads
    fastplong_hifi_reports  = fastplong_json_out
}


def prepareReadsAndAdapters(main_in) {
    return main_in
            .filter { it -> it.meta.group }
            .map { it -> [it.meta, it.meta.group, it.meta.hifi_trim, it.meta.hifireads, it.meta.hifi_adapters, it.meta.hifi_fastplong_args] }
            .groupTuple(by: 1)
            .map {
                it ->
                    [
                        meta: [
                            id: it[1],
                            metas: it[0],
                            trim: it[2][0], // These go in via config
                            hifi_fastplong_args: it[5][0]
                            ],
                        hifireads: it[3][0],
                        hifi_adapters: it[4][0]
                    ]
            }
            .mix(
                main_in
                    .filter { it -> !it.meta.group }
                    .map {
                        it ->
                        [
                            meta: it.meta,
                            hifireads: it.meta.hifireads,
                            hifi_adapters: it.meta.hifi_adapters,
                        ]
                    }
            )
            .multiMap {
                it ->
                reads: [it.meta, it.hifireads]
                adapters: it.hifi_adapters ?: []
            }
}


def processFilteredReads(ch_reads) {
    return ch_reads
        .filter { it -> it[0].metas }
        .flatMap { it -> // it looks like [meta, output_path]
            it[0].metas
                  .collect { metas -> [ meta: metas - metas.subMap("hifireads") + [hifireads: it[1]] ] }
        }
        .mix(ch_reads
            .filter { it -> !it[0].metas }
            .map {
                meta, hifireads -> [ meta: meta - meta.subMap("hifireads") + [ hifireads: hifireads ] ]
            }
        )
}