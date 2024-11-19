include { MEDAKA } from '../../../../../modules/nf-core/medaka/main'

workflow RUN_MEDAKA {
  take:
    in_reads
    assembly
  
  main:
    in_reads
      .join(assembly)
      .set { medaka_in }

    MEDAKA(medaka_in)

    MEDAKA
      .out
      .assembly
      .set { medaka_out }
  
  emit:
     medaka_out
}