include { TRIMGALORE } from '../../../modules/nf-core/trimgalore/main'
include { MERYL_COUNT } from '../../../modules/nf-core/meryl/count/main'
include { MERYL_UNIONSUM } from '../../../modules/nf-core/meryl/unionsum/main'

workflow PREPARE_SHORTREADS {
    take:
    shortreads_in

    main:
    Channel.empty().set { ch_versions }

    //shortreads_in.view { it -> "Shortread input: $it"}

    shortreads_in
        .map { create_shortread_channel(it) }
        .set { shortreads }


    // use modified shortread channel

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
            trim: it.shortreads_trim
            no_trim: !it.shortreads_trim
        }
        .set { shortreads }

    TRIMGALORE(shortreads.trim)

    // unite branched:
    // add trimmed reads to trim channel, then mix with shortreads.no_trim

    shortreads.trim
        .map { it -> it - it.subMap["shortreads"] }
        .map { it -> it.collect { entry -> [ entry.value, entry ] } }
        .join(
            TRIMGALORE.out.reads
                .map { it -> [meta: [id: it[0].id], shortreads: it[1]]}
                .map { it -> it.collect { entry -> [ entry.value, entry ] } }
        )
        .map { it -> it.collect { _entry, map -> [ (map.key): map.value ] }.collectEntries() }
        .mix( shortreads.no_trim )
        .set { shortreads }

    ch_versions = ch_versions.mix(TRIMGALORE.out.versions)

    MERYL_COUNT(shortreads.map { it -> [ it.meta, it.shortreads ] }, params.meryl_k)
    MERYL_UNIONSUM(MERYL_COUNT.out.meryl_db, params.meryl_k)
    MERYL_UNIONSUM.out.meryl_db.set { meryl_kmers }

    versions = ch_versions.mix(MERYL_COUNT.out.versions).mix(MERYL_UNIONSUM.out.versions)

    emit:
    shortreads
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
