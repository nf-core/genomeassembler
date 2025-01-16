include { COLLECT_READS } from '../../../../modules/local/collect_reads/main'

workflow COLLECT {
  take:
  ch_input

  main:

  ch_input
    .map { row -> [row.meta, row.ontreads] }
    .set { reads }

  if (params.collect) {
    COLLECT_READS(reads)

    COLLECT_READS.out.combined_reads.set { reads }
  }

  emit:
  reads
}
