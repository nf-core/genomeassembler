include { CHOP } from './chop/main'
include { COLLECT } from './collect/main'
include { RUN_NANOQ } from './run_nanoq/main'

workflow PREPARE_ONT {
  take: inputs

  main:
    COLLECT(inputs)

    CHOP(COLLECT.out)

    CHOP
      .out
      .set { trimmed }

    RUN_NANOQ(trimmed)

    RUN_NANOQ
      .out
      .median_length
      .set { med_len }

    RUN_NANOQ
      .out
      .report
      .set { nanoq_report }

    RUN_NANOQ
      .out
      .stats
      .set { nanoq_stats }

  emit:
      trimmed
      med_len
      nanoq_report
      nanoq_stats
}