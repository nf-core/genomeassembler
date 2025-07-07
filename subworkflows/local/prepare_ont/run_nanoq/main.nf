include { NANOQ } from '../../../../modules/local/nanoq/main'

workflow RUN_NANOQ {
    take:
    inputs

    main:
    Channel.empty().set { versions }
    inputs.map {
        it ->
        [
            meta: it.meta,
            ontreads: it.ontreads
        ]
    }
        .set { in_reads }

    NANOQ(in_reads)

    NANOQ.out.report.set { report }

    NANOQ.out.stats.set { stats }

    NANOQ.out.median_length.set { median_length }

    NANOQ.out.versions.set { versions }

    emit:
    report
    stats
    median_length
    versions
}
