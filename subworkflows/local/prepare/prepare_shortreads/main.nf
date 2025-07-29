include { TRIMGALORE } from '../../../../modules/nf-core/trimgalore/main'
include { MERYL_COUNT } from '../../../../modules/nf-core/meryl/count/main'
include { MERYL_UNIONSUM } from '../../../../modules/nf-core/meryl/unionsum/main'

workflow PREPARE_SHORTREADS {
    take:
    shortreads_in

    main:
    Channel.empty().set { ch_versions }

    shortreads_in
        .map { create_shortread_channel(it) }
        .set { shortreads }

    shortreads_in
        .map {
            it -> it - it.subMap('shortread_F', 'shortread_R', 'paired')
        }
        .map {
            it -> it.collect { entry -> [ entry.value, entry ] }
        }
        .join(
            shortreads
                .map { it -> [meta: [id: it[0].id], shortreads: it[1]]}
                .map { it -> it.collect { entry -> [ entry.value, entry ] } }
        )
        .map { it -> it.collect { _entry, map -> [ (map.key): map.value ] }.collectEntries() }
        .set { shortreads }

    // shortread trimming
    //shortreads.view { it -> "shortreads: $it" }

    shortreads
        .branch {
            it ->
            trim: it.shortread_trim
            no_trim: !it.shortread_trim
        }
        .set { shortreads }

    shortreads
        .trim
        .filter { it -> it.group  }
        .map { it -> [it.meta, it.group, it.shortreads] }
        // Create a group
        .groupTuple(by: 1)
        .map {
            it ->
                [
                    [ id: it[1], ids: it[0].id.collect().join("+") ],
                    it[2].unique()[0]
                ]
        }
        .mix(shortreads.trim
            .filter { it -> !it.group }
            .map {
                it -> [ it.meta, it.shortreads ]
            }
        )
        .set { trimgalore_in }

    TRIMGALORE(trimgalore_in)

    TRIMGALORE.out.reads
        .filter { it -> it[0].ids }
        .flatMap { it ->
            it[0].ids.tokenize("+").collect {
                sample -> [meta: [ id: sample ], shortreads: it[1] ]
            }
        }
        .mix(
            TRIMGALORE.out.reads
                .filter { it -> !it[0].ids }
                .map { it -> [ meta: [ id: it[0].id ], shortreads: it[1] ] }
        )
        .map { it -> it.collect { entry -> [ entry.value, entry ] } }
        .set { trimmed_reads }

    // unite branched:
    // add trimmed reads to trim channel, then mix with shortreads.no_trim

    shortreads.trim
        .map { it -> it - it.subMap("shortreads") }
        .map { it -> it.collect { entry -> [ entry.value, entry ] } }
        .join( trimmed_reads )
        .map { it -> it.collect { _entry, map -> [ (map.key): map.value ] }.collectEntries() }
        .mix( shortreads.no_trim )
        .set { shortreads }

    ch_versions = ch_versions.mix(TRIMGALORE.out.versions)

    shortreads
        .filter { it -> it.merqury }
        .filter { it -> it.group  }
        .map { it -> [it.meta, it.group, it.shortreads, it.meryl_k] }
        // Create a group
        .groupTuple(by: 1)
        .map {
            it -> [
                meta: [ id: it[1], ids: it[0].id.collect().join("+") ],
                shortreads: it[2].unique()[0],
                meryl_k: it[3].unique()[0]
            ]
        }
        .mix(shortreads
            .filter { it -> it.merqury }
            .filter { it -> !it.group  }
            .map { it -> [meta: it.meta, shortreads: it.shortreads, meryl_k: it.meryl_k]}
        )
        .multiMap { it ->
            reads: [ it.meta, it.shortreads ]
            kmer_size: it.meryl_k
        }
        .set { meryl_in }

    MERYL_COUNT(meryl_in.reads, meryl_in.kmer_size)

    MERYL_UNIONSUM(MERYL_COUNT.out.meryl_db, params.meryl_k)

    MERYL_UNIONSUM.out.meryl_db
        .filter { it -> it[0].ids }
        .flatMap { it ->
            it[0].ids
                .tokenize("+")
                .collect { sample -> [ [ id: sample ], it[1] ] }
            }
        .mix(MERYL_UNIONSUM.out.meryl_db
            .filter { it -> !it[0].ids }
            .map {
                it -> [ [ id: it[0].id ], it[1] ]
            }
        ).set { meryl_kmers }

    shortreads_in
        .map {
            it -> it - it.subMap('shortread_F', 'shortread_R', 'paired')
        }
        .map { it -> it.collect { entry -> [ entry.value, entry ] } }
        .join(
            shortreads
                .map { it -> [meta: [id: it.meta.id], shortreads: it.shortreads]}
                .map { it -> it.collect { entry -> [ entry.value, entry ] } }
        )
        .map { it -> it.collect { _entry, map -> [ (map.key): map.value ] }.collectEntries() }
        .set { main_out }

    versions = ch_versions.mix(MERYL_COUNT.out.versions).mix(MERYL_UNIONSUM.out.versions)

    emit:
    main_out
    meryl_kmers
    versions
}

def create_shortread_channel(row) {
    // create meta map
    def meta = [:]
    meta.id = row.meta.id
    meta.paired = row.paired.toBoolean()
    meta.single_end = !meta.paired

    // add path(s) of the fastq file(s) to the meta map
    def shortreads = []
    if (!file(row.shortread_F).exists()) {
        exit(1, "ERROR: shortread_F fastq file does not exist!\n${row.shortread_F}")
    }
    if (!meta.paired) {
        shortreads = [meta, [file(row.shortread_F)]]
    }
    else {
        if (!file(row.shortread_R).exists()) {
            exit(1, "ERROR: shortread_R fastq file does not exist!\n${row.shortread_R}")
        }
        shortreads = [meta, [file(row.shortread_F), file(row.shortread_R)]]
    }
    return shortreads
}
