include { LINKS } from '../../../modules/local/links/main'
include { MAP_TO_ASSEMBLY } from '../../mapping/map_to_assembly/main'
include { RUN_QUAST } from '../../qc/quast/main'
include { RUN_BUSCO } from '../../qc/busco/main'
include { YAK_QC } from '../../qc/yak/main'
include { RUN_LIFTOFF } from '../../liftoff/main'
include { MERQURY_QC } from '../../qc/merqury/main'

workflow RUN_LINKS {
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
      .join(in_reads)
      .set { links_in }
    LINKS(links_in)

    LINKS
      .out
      .scaffolds
      .set { scaffolds }
    MAP_TO_ASSEMBLY(in_reads, scaffolds)

    RUN_QUAST(scaffolds, inputs, ch_aln_to_ref, MAP_TO_ASSEMBLY.out.aln_to_assembly_bam)

    RUN_BUSCO(scaffolds)

    if(params.short_reads) MERQURY_QC(RUN_MEDAKA.out, meryl_kmers)

    YAK_QC(scaffolds, yak_kmers)

    if(params.lift_annotations) RUN_LIFTOFF(LINKS.out.scaffolds, inputs)
    
  emit:
     scaffolds
}