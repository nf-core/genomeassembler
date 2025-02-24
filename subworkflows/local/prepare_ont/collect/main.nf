include { COLLECT_READS } from '../../../../modules/local/collect_reads/main'

workflow COLLECT {
    take:
    ch_input

    main:
    Channel.empty().set { ch_versions }

    ch_input
        .map { row -> [row.meta, row.ontreads] }
        .set { reads }

    if (params.collect) {
        COLLECT_READS(reads)
        COLLECT_READS.out.combined_reads.set { reads }
        ch_versions.mix(COLLECT_READS.out.versions)
    }
    versions = ch_versions

    emit:
    reads
    versions
}
