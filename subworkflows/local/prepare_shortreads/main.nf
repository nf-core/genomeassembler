include { TRIMGALORE } from '../../../modules/nf-core/trimgalore/main'
include { MERYL_COUNT } from '../../../modules/nf-core/meryl/count/main'
include { MERYL_UNIONSUM } from '../../../modules/nf-core/meryl/unionsum/main'

workflow PREPARE_SHORTREADS {
    take:
    main_in

    main:
    Channel.empty().set { ch_versions }

    main_in
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
            trim: it.shortread_trim
            no_trim: !it.shortread_trim
        }
        .set { shortreads }

    TRIMGALORE(shortreads.trim.map { it -> [it.meta, it.shortreads] })

    // unite branched:
    // add trimmed reads to trim channel, then mix with shortreads.no_trim

    shortreads
        .trim
        .map { it -> it - it.subMap("shortreads") }
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
    shortreads
                .filter { it -> it.merqury }
                .multiMap { it ->
                    reads: [ it.meta, it.shortreads ]
                    kmer_size: it.meryl_k
                }
                .set { meryl_in }
    MERYL_COUNT(meryl_in.reads, meryl_in.kmer_size)
    MERYL_UNIONSUM(MERYL_COUNT.out.meryl_db, params.meryl_k)
    MERYL_UNIONSUM.out.meryl_db.set { meryl_kmers }

    main_in
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
