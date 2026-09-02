include { FASTPLONG as FASTPLONG_HIFI } from '../../../../modules/nf-core/fastplong/main'

workflow PREPARE_HIFI {
    take:
    main_in // should contain only samples with hifireads

    main:

    main_in.dump(tag: "Prepare-HIFI input")

    ch_fastplong_in = main_in
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

    ch_fastplong_in.reads.dump(tag: "HiFI fastplong reads in")

    FASTPLONG_HIFI(ch_fastplong_in.reads, ch_fastplong_in.adapters, false, false )

    fastplong_reads_out = FASTPLONG_HIFI
        .out
        .reads
        .filter { it -> it[0].metas }
        .flatMap { it -> // it looks like [meta, output_path]
            it[0].metas
                  .collect { metas -> [ meta: metas - metas.subMap("hifireads") + [hifireads: it[1]] ] }
        }
        .mix(FASTPLONG_HIFI.out.reads
            .filter { it -> !it[0].metas }
            .map {
                meta, hifireads -> [ meta: meta - meta.subMap("hifireads") + [ hifireads: hifireads ] ]
            }
        )

    fastplong_json_out = FASTPLONG_HIFI
        .out
        .json
        .filter { it -> it[0].metas }
        .flatMap { it ->
            it[0].metas
                .collect { meta -> [ meta, it[1] ] }
            }
        .mix(FASTPLONG_HIFI.out.json
            .filter { it -> !it[0].metas }
        )

    fastplong_reads_out.dump(tag: "Prepare-HIFI output")

    emit:
    main_out                = fastplong_reads_out
    fastplong_hifi_reports  = fastplong_json_out
}
