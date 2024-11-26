include { PORECHOP_PORECHOP as PORECHOP } from '../../../../modules/nf-core/porechop/porechop/main'

workflow CHOP {
  take: in_reads

  main:
  Channel.empty().set { chopped_reads }
  if(params.porechop) {
    PORECHOP(in_reads)
    PORECHOP
      .out
      .reads
      .set { chopped_reads }
  } else {
    in_reads
      .set { chopped_reads }
  }
  
  
  emit:
    chopped_reads
}