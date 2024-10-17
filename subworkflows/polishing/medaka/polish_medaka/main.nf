include { RUN_MEDAKA } from '../run_medaka/main'
include { MAP_TO_ASSEMBLY } from '../../../mapping/map_to_assembly/main'
include { RUN_BUSCO } from '../../../qc/busco/main'
include { RUN_QUAST } from '../../../qc/quast/main'
include { YAK_QC } from '../../../qc/yak/main'
include { RUN_LIFTOFF } from '../../../liftoff/main'

workflow POLISH_MEDAKA {
    take:
      ch_input
      in_reads
      assembly
      ch_aln_to_ref
      shortread_kmers

    main:
      RUN_MEDAKA(in_reads, assembly)
      
      MAP_TO_ASSEMBLY(in_reads, RUN_MEDAKA.out)

      RUN_QUAST(RUN_MEDAKA.out, ch_input, ch_aln_to_ref, MAP_TO_ASSEMBLY.out.aln_to_assembly_bam)

      RUN_BUSCO(RUN_MEDAKA.out)

      YAK_QC(RUN_MEDAKA.out, shortread_kmers)

      if(params.lift_annotations) {
        RUN_LIFTOFF(RUN_MEDAKA.out, ch_input)
      }
    emit:
      RUN_MEDAKA.out
}