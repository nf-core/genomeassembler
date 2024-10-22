include { PILON } from '../../../../../modules/local/pilon/main'
workflow RUN_PILON {
    take:
      assembly_in
      aln_to_assembly_bam_bai

    main:
      assembly_in
        .join(aln_to_assembly_bam_bai)
        .set { pilon_in }

      PILON(pilon_in, "bam")
    
    emit:
      PILON.out.improved_assembly
}