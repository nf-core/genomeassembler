include { NANOQ } from '../../../../modules/local/nanoq/main'

workflow RUN_NANOQ {
    take:
    in_reads

    main:
    Channel.empty().set { versions }

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
