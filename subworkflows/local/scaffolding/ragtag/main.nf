include { RAGTAG_SCAFFOLD } from '../../../../modules/local/ragtag/main'
include { MAP_TO_ASSEMBLY } from '../../mapping/map_to_assembly/main'
include { RUN_QUAST } from '../../qc/quast/main'
include { RUN_BUSCO } from '../../qc/busco/main'
include { RUN_LIFTOFF } from '../../liftoff/main'
include { MERQURY_QC } from '../../qc/merqury/main'


workflow RUN_RAGTAG {
  take:
    inputs
    in_reads
    assembly
    references
    ch_aln_to_ref
    yak_kmers
    meryl_kmers

  main:
    assembly
      .join(references)
      .set { ragtag_in }

    RAGTAG_SCAFFOLD(ragtag_in)

    RAGTAG_SCAFFOLD
      .out
      .corrected_assembly
      .set { ragtag_scaffold_fasta }

    RAGTAG_SCAFFOLD
      .out
      .corrected_agp
      .set { ragtag_scaffold_agp }

    MAP_TO_ASSEMBLY(in_reads, ragtag_scaffold_fasta)

    RUN_QUAST(ragtag_scaffold_fasta, inputs, ch_aln_to_ref, MAP_TO_ASSEMBLY.out.aln_to_assembly_bam)

    RUN_BUSCO(ragtag_scaffold_fasta)

    if(params.short_reads) MERQURY_QC(ragtag_scaffold_fasta, meryl_kmers)

    if(params.lift_annotations) RUN_LIFTOFF(RAGTAG_SCAFFOLD.out.corrected_assembly, inputs)

  emit:
      ragtag_scaffold_fasta
      ragtag_scaffold_agp
}