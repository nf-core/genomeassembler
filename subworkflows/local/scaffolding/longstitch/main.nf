include { LONGSTITCH } from '../../../../modules/local/longstitch/main'
include { MAP_TO_ASSEMBLY } from '../../mapping/map_to_assembly/main'
include { RUN_QUAST } from '../../qc/quast/main'
include { RUN_BUSCO } from '../../qc/busco/main'
include { RUN_LIFTOFF } from '../../liftoff/main'
include { MERQURY_QC } from '../../qc/merqury/main'

workflow RUN_LONGSTITCH {
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
      .join(in_reads)
      .set { longstitch_in }

    LONGSTITCH(longstitch_in)

    LONGSTITCH
      .out
      .ntlLinks_arks_scaffolds
      .set { scaffolds }

    MAP_TO_ASSEMBLY(in_reads, scaffolds)

    RUN_QUAST(scaffolds, inputs, ch_aln_to_ref, MAP_TO_ASSEMBLY.out.aln_to_assembly_bam)
    RUN_QUAST
      .out
      .quast_tsv
      .set { quast_out }

    RUN_BUSCO(scaffolds)
    RUN_BUSCO
      .out
      .batch_summary
      .set { busco_out }

    if(params.short_reads) {
      MERQURY_QC(scaffolds, meryl_kmers)
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
        .join(
            MERQURY_QC
              .out
              .assembly_qv
          )
        .set { merqury_report_files }
      }
    if(params.lift_annotations) RUN_LIFTOFF(LONGSTITCH.out.ntlLinks_arks_scaffolds, inputs)

  emit:
     scaffolds
     quast_out
     busco_out
     merqury_report_files
}