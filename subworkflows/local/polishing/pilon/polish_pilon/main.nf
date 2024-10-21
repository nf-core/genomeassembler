include { RUN_PILON } from '../run_pilon/main'
include { MAP_SR } from '../../../mapping/map_sr/main'
include { MAP_TO_ASSEMBLY } from '../../../mapping/map_to_assembly/main'
include { RUN_BUSCO } from '../../../qc/busco/main'
include { RUN_QUAST } from '../../../qc/quast/main'
include { YAK_QC } from '../../../qc/yak/main'
include { RUN_LIFTOFF } from '../../../liftoff/main'
include { MERQURY_QC } from '../../../qc/merqury/main'

workflow POLISH_PILON {
  take:
    ch_input
    shortreads
    in_reads
    assembly
    ch_aln_to_ref
    yak_kmers
    meryl_kmers
  
  main:
    MAP_SR(shortreads, assembly)

    RUN_PILON(assembly, MAP_SR.out.aln_to_assembly_bam_bai)

    RUN_PILON
       .out
       .set { pilon_improved }

    MAP_TO_ASSEMBLY(in_reads, pilon_improved)

    RUN_QUAST(pilon_improved, ch_input, ch_aln_to_ref, MAP_TO_ASSEMBLY.out.aln_to_assembly_bam)
   
    RUN_BUSCO(pilon_improved)

    if(params.short_reads) MERQURY_QC(pilon_improved, meryl_kmers)

    YAK_QC(pilon_improved, yak_kmers)

    if(params.lift_annotations) RUN_LIFTOFF(RUN_PILON.out, ch_input)
  
  emit:
    pilon_improved
}