include { PORECHOP } from '../../../modules/porechop/main'

workflow CHOP {
  take: in_reads

  main:
  
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