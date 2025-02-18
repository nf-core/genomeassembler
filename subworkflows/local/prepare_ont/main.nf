include { CHOP } from './chop/main'
include { COLLECT } from './collect/main'
include { RUN_NANOQ } from './run_nanoq/main'

workflow PREPARE_ONT {
    take:
    inputs

    main:
    Channel.empty().set { ch_versions }

    COLLECT(inputs)

    CHOP(COLLECT.out)

    CHOP.out.set { trimmed }

    RUN_NANOQ(trimmed)

    RUN_NANOQ.out.median_length.set { med_len }

    RUN_NANOQ.out.report.set { nanoq_report }

    RUN_NANOQ.out.stats.set { nanoq_stats }

    versions = ch_versions.mix(COLLECT.out.versions).mix(CHOP.out.versions).mix(RUN_NANOQ.out.versions)

    emit:
    trimmed
    med_len
    nanoq_report
    nanoq_stats
    versions
}
