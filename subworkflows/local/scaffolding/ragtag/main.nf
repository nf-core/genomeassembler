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
    meryl_kmers

  main:
    Channel.empty().set { quast_out }
    Channel.empty().set { busco_out }
    Channel.empty().set { merqury_report_files }
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
    RUN_QUAST
      .out
      .quast_tsv
      .set { quast_out }
    RUN_BUSCO(ragtag_scaffold_fasta)
    RUN_BUSCO
      .out
      .busco_short_summary_txt
      .set { busco_out }
    if(params.short_reads) {
      MERQURY_QC(ragtag_scaffold_fasta, meryl_kmers)
      MERQURY_QC
        .out
        .stats
        .join(
          MERQURY_QC
            .out
            .spectra_asm_hist
        )
        .join(
          MERQURY_QC
            .out
            .spectra_cn_hist
        )
        .set { merqury_report_files }
    }
    
    if(params.lift_annotations) RUN_LIFTOFF(RAGTAG_SCAFFOLD.out.corrected_assembly, inputs)

  emit:
      ragtag_scaffold_fasta
      ragtag_scaffold_agp
      quast_out
      busco_out
      merqury_report_files
}