
include { CHOP } from './chop/main'
include { COLLECT } from './collect/main'
include { RUN_NANOQ } from './run_nanoq/main'

workflow PREPARE_ONT {
  take: inputs

  main:
    COLLECT(inputs)

    CHOP(COLLECT.out)

    trimmed = CHOP.out

    RUN_NANOQ(trimmed)

    med_len = RUN_NANOQ.out.median_length

  emit:
      trimmed
      med_len
}