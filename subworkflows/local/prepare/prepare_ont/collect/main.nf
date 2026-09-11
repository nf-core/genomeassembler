include { COLLECT_READS } from '../../../../../modules/local/collect_reads/main'

workflow COLLECT {
    take:
    ch_input

    main:
    reads = ch_input
        .filter {
            it -> it.ont_collect
        }
        .map { row -> [row.meta, row.meta.ontreads] }

    COLLECT_READS(reads)
    reads = COLLECT_READS.out.combined_reads

    emit:
    reads
}
