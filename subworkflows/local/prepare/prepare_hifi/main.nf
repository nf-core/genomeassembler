include { FASTPLONG as FASTPLONG_HIFI } from '../../../../modules/nf-core/fastplong/main'

workflow PREPARE_HIFI {
    take:
    main_in // should contain only samples with hifireads

    main:
    Channel.empty().set { ch_versions }

    main_in.dump(tag: "Prepare-HIFI input")
    main_in
        .filter { it -> it.group }
        .map { it -> [it.meta, it.group, it.hifi_trim, it.hifireads, it.hifi_adapters, it.hifi_fastplong_args] }
        .groupTuple(by: 1)
        .map {
            it ->
                [
                    meta: [
                        id: it[1], ids: it[0].id.collect().join("+"),
                        trim: it[2].unique()[0],
                        hifi_fastplong_args: it[5].unique()[0]
                        ],
                    hifireads: it[3].unique()[0],
                    hifi_adapters: it[4].unique()[0]
                ]
        }
        .mix(
            main_in
                .filter { it -> !it.group }
                .map {
                    it ->
                    [
                        meta: [
                            id: it.meta.id,
                            trim: it.hifi_trim,
                            hifi_fastplong_args: it.hifi_fastplong_args
                            ],
                        hifireads: it.hifireads,
                        hifi_adapters: it.hifi_adapters,
                    ]
                }
        )
        .multiMap {
            it ->
            reads: [it.meta, it.hifireads]
            adapters: it.hifi_adapters ?: []
        }
        .set { ch_fastplong_in }

    FASTPLONG_HIFI(ch_fastplong_in.reads, ch_fastplong_in.adapters, false, false )

    FASTPLONG_HIFI
        .out
        .reads
        .filter { it -> it[0].ids }
        .flatMap { it ->
            it[0].ids
                .tokenize("+")
                .collect { sample -> [ meta: [ id: sample ], hifireads: it[1] ] }
            }
        .mix(FASTPLONG_HIFI.out.reads
            .filter { it -> !it[0].ids }
            .map {
                it -> [ meta: [ id: it[0].id ], hifireads: it[1] ]
            }
        )
        .set { fastplong_reads_out }

    FASTPLONG_HIFI
        .out
        .json
        .filter { it -> it[0].ids }
        .flatMap { it ->
            it[0].ids
                .tokenize("+")
                .collect { sample -> [ [ id: sample ], it[1] ] }
            }
        .mix(FASTPLONG_HIFI.out.json
            .filter { it -> !it[0].ids }
            .map {
                it -> [ [ id: it[0].id ], it[1] ]
            }
        )
        .set { fastplong_json_out }

     // inputs are joined to outputs
    main_in
        .map { it -> it - it.subMap('hifireads') }
        .map { it -> it.collect { entry -> [ entry.value, entry ] } }
        .join(
            fastplong_reads_out
                .map { it -> it.collect { entry -> [ entry.value, entry ] } }
        )
        .map { it -> it.collect { _entry, map -> [ (map.key): map.value ] }.collectEntries() }
        .set { main_out }

    main_out.dump(tag: "Prepare-HIFI output")

    versions = ch_versions.mix(FASTPLONG_HIFI.out.versions)

    emit:
    main_out
    fastplong_hifi_reports = fastplong_json_out
    versions
}
