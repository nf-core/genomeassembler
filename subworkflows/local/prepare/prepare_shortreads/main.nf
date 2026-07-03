include { FASTP                 } from '../../../../modules/nf-core/fastp/main'
include { FASTP as FASTP_HIC    } from '../../../../modules/nf-core/fastp/main'
include { MERYL_COUNT           } from '../../../../modules/nf-core/meryl/count/main'
include { MERYL_UNIONSUM        } from '../../../../modules/nf-core/meryl/unionsum/main'

workflow PREPARE_SHORTREADS {
    take:
    shortreads_in

    main:

    shortreads = shortreads_in
        .map { row -> row.meta.shortread_F ? create_shortread_channel(row.meta) : row } // function below
        .branch {
            it ->
                trim: it.meta.shortread_trim
                no_trim: !it.meta.shortread_trim
        }

    hic_trim = shortreads_in
        .map { row -> (row.meta.hic_F && row.meta.scaffold_hic) ? create_hic_shortread_channel(row.meta) : row }
        .branch {
            row ->
                trim: row.meta.hic_trim && row.meta.scaffold_hic
                no_trim: !row.meta.hic_trim
        }
    hic_trim.trim.dump(tag: "hic trim channel")

    trim_in = shortreads
        .trim
        .filter { it -> it.meta.group }
        .map { it -> [it.meta, it.meta.group] }
        .groupTuple(by: 1)
        .map {
            it ->
                [
                    [
                        id: it[1], // the group
                        metas: it[0]
                    ],
                    it[0].shortreads[0], // Pull path from meta
                    []
                ]
        }
        .mix(
            shortreads
                .trim
                .filter { it -> !it.meta.group }
                .map {
                it -> [ it.meta, it.meta.shortreads, [] ]
                }
        )

    hic_trim_in = hic_trim
        .trim
        .filter { it -> it.meta.group }
        .map {it -> [it.meta, it.meta.group]}
        .groupTuple(by: 1)
        .map {
            it ->
                [
                    [
                        id: it[1], // the group
                        metas: it[0]
                    ],
                    it[0].hic_reads[0], // Pull path from meta
                    []
                ]
        }
        .mix(
            hic_trim
                .trim
                .filter { it -> !it.meta.group }
                .map {
                    it -> [ it.meta, it.meta.hic_reads, [] ]
                }
        )

    trim_in.dump(tag: "Trim in")

    FASTP(trim_in, false, false, false)

    trimmed_reads = FASTP.out.reads
        .filter { it -> it[0].metas }
        .flatMap { it -> // looks like [meta <[id, metas]>, output_path]
            it[0].metas
                  .collect { meta -> [ meta: meta - meta.subMap("shortreads") + [ shortreads: it[1] ] ] }
        }
        .mix(
            FASTP.out.reads
                .filter { it -> !it[0].metas }
                .map { it -> [ meta: it[0] - it[0].subMap("shortreads") + [ shortreads: it[1] ] ] }
        )


    trimmed_reads.dump(tag: "Trim out")
    // unite branched:
    // add trimmed reads to trim channel, then mix with shortreads.no_trim

    FASTP_HIC(hic_trim_in, false, false, false)

    hic_trimmed_reads = FASTP_HIC.out.reads
        .filter { it -> it[0].metas }
        .flatMap { it -> // looks like [meta <[id, metas]>, output_path]
            it[0].metas
                  .collect { meta -> [ meta: meta - meta.subMap("hic_reads") + [ hic_reads: it[1] ] ] }
        }
        .mix(
            FASTP_HIC.out.reads
                .filter { it -> !it[0].metas }
                .map { it -> [ meta: it[0] - it[0].subMap("hic_reads") + [ hic_reads: it[1] ] ] }
        )

    shortreads = trimmed_reads
        .mix( shortreads.no_trim )

    // add HiC trimmed to those that need it

    shortreads = shortreads
        .filter { row -> row.meta.hic_trim }
        .map { row -> [ row.meta.id, row.meta ] }
        .combine(
            hic_trimmed_reads
                .map { it  ->
                    [
                        it.meta.id,
                        it.meta.hic_reads
                    ]
                },
                by: 0
        )
        .map {
            _id, meta, trimmed_hic_reads ->
                [
                    meta: meta - meta.subMap("hic_reads") + [ hic_reads: trimmed_hic_reads ]
                ]
        }
        .mix(
            trimmed_reads
                .filter { row -> !row.meta.hic_trim }
                .map { it-> [meta: it.meta - it.meta.subMap("hic_reads") + [hic_reads: null]]}
        )

    meryl_in = shortreads
        .filter { it -> it.meta.merqury }
        .filter { it -> it.meta.group  }
        .map { it -> [ it.meta, it.meta.group, it.meta.shortreads, it.meta.meryl_k ] }
        // Create a group
        .groupTuple(by: 1)
        .map {
            it -> [
                meta: [ id: it[1], metas: it[0] ],
                shortreads: it[2][0],
                meryl_k: it[3][0]
            ]
        }
        .mix(shortreads
            .filter { it -> it.meta.merqury }
            .filter { it -> !it.meta.group  }
            .map { it -> [meta: it.meta, shortreads: it.meta.shortreads, meryl_k: it.meta.meryl_k]}
        )
        .multiMap { it ->
            reads: [ it.meta, it.shortreads ]
            kmer_size: it.meryl_k
        }

    MERYL_COUNT(meryl_in.reads, meryl_in.kmer_size)

    MERYL_UNIONSUM(MERYL_COUNT.out.meryl_db, params.meryl_k)

    meryl_kmers = MERYL_UNIONSUM.out.meryl_db
        .filter { it -> it[0].metas }
        .flatMap { it -> // looks like [meta <[id, metas]>, output_path]
            it[0].metas
                  .collect { meta -> [ meta, it[1] ] }
        }
        .mix(MERYL_UNIONSUM.out.meryl_db
            .filter { it -> !it[0].metas }
            .map {
                it -> [ it[0], it[1] ]
            }
        )
        .map {meta , kmers -> [meta.id, kmers]}

    emit:
    main_out        = shortreads
    fastp_json      = FASTP.out.json
    meryl_kmers
}

def create_shortread_channel(row) { // This function expects a meta map as input
    // create meta map
    def meta = row
    meta.paired = row.paired
    meta.single_end = !meta.paired

    // add path(s) of the fastq file(s) to the meta map
    def shortreads = []
    if (!file(row.shortread_F).exists()) {
        exit(1, "ERROR: shortread_F fastq file does not exist!\n${row.shortread_F}")
    }
    if (!meta.paired) {
        shortreads = [meta: meta + [shortreads: [row.shortread_F]]]
    }
    else {
        if (!file(row.shortread_R).exists()) {
            exit(1, "ERROR: shortread_R fastq file does not exist!\n${row.shortread_R}")
        }
        shortreads = [ meta: meta + [shortreads:  [row.shortread_F, row.shortread_R]] ]
    }
    return shortreads
}

def create_hic_shortread_channel(row) { // This function expects a meta map as input
    // create meta map
    def meta = row

    // add path(s) of the fastq file(s) to the meta map
    def hic_reads = []
    if (!file(row.hic_F).exists()) {
        exit(1, "ERROR: hic_F fastq file does not exist!\n${row.hic_F}")
    }
    if (!file(row.hic_R).exists()) {
        exit(1, "ERROR: hic_R fastq file does not exist!\n${row.hic_R}")
    }
    hic_reads = [ meta: meta + [hic_reads:  [row.hic_F, row.hic_R]] ]
    return hic_reads
}
