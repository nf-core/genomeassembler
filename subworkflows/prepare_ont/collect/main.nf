include { COLLECT_READS } from '../../../modules/local/collect_reads/main'

workflow COLLECT {
  take: ch_input

  main:
  
    ch_input
      .map { row -> [row.sample, row.ontreads] }
      .set { in_reads }

    if(params.collect) {
      COLLECT_READS(in_reads)

      COLLECT_READS
        .out
        .combined_reads
        .set { in_reads }
    }

  emit:
    in_reads
 }