include { COLLECT_READS } from '../../../../modules/local/collect_reads/main'

workflow COLLECT {
    take:
    ch_input

    main:
    Channel.empty().set { ch_versions }

    ch_input
        .filter {
            it -> it.ont_collect
        }
        .map { row -> [row.meta, row.ontreads] }
        .set { reads }

    COLLECT_READS(reads)
    COLLECT_READS.out.combined_reads.set { reads }
    ch_versions.mix(COLLECT_READS.out.versions)

    versions = ch_versions

    ch_input
        .map { it -> it - it.submap('ontreads') }
        .map { it -> it.collect { entry -> [ entry.value, entry ] } }
        .join(reads
            .map { it -> [meta: it[0], ontreads:it[1]] }
            .map { it -> it.collect { entry -> [ entry.value, entry ] } }
        )
        .map { it -> it.collect { _entry, map -> [ (map.key): map.value ] }.collectEntries() }
        .set { reads }

    emit:
    reads
    versions
}
