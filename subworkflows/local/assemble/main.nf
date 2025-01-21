include { FLYE } from '../../../modules/nf-core/flye/main'
include { HIFIASM } from '../../../modules/nf-core/hifiasm/main'
include { HIFIASM as HIFIASM_ONT } from '../../../modules/nf-core/hifiasm/main'
include { GFA_2_FA } from '../../../modules/local/gfa2fa/main'
include { MAP_TO_ASSEMBLY } from '../mapping/map_to_assembly/main'
include { MAP_TO_REF } from '../mapping/map_to_ref/main'
include { RUN_QUAST } from '../qc/quast/main'
include { RUN_BUSCO } from '../qc/busco/main'
include { MERQURY_QC } from '../qc/merqury/main'
include { RUN_LIFTOFF } from '../liftoff/main'
include { RAGTAG_SCAFFOLD } from '../../../modules/local/ragtag/main'


workflow ASSEMBLE {
  take:
  ont_reads // meta, reads
  hifi_reads // meta, reads
  ch_input
  genomescope_out
  meryl_kmers

  main:
  // Empty channels 
  Channel.empty().set { ch_refs }
  Channel.empty().set { ch_ref_bam }
  Channel.empty().set { ch_assembly_bam }
  Channel.empty().set { ch_assembly }
  Channel.empty().set { assembly_quast_reports }
  Channel.empty().set { assembly_busco_reports }
  Channel.empty().set { assembly_merqury_reports }
  Channel.empty().set { flye_inputs }
  Channel.empty().set { hifiasm_inputs }
  Channel.empty().set { longreads }

  if (params.use_ref) {
    ch_input
      .map { row -> [row.meta, row.ref_fasta] }
      .set { ch_refs }
  }

  if (params.skip_assembly) {
    // Sample sheet layout when skipping assembly
    // sample,ontreads,assembly,ref_fasta,ref_gff
    ch_input
      .map { row -> [row.meta, row.assembly] }
      .set { ch_assembly }
  }
  if (!params.skip_assembly) {
    def hifi_only = params.hifi && !params.ont ? true : false
    // Define inputs for flye
    if (params.assembler == "flye") {
      if (params.hifi) {
        if (!hifi_only) {
          error('Cannot combine hifi and ont reads with flye')
        }
        hifi_reads
          .map { it -> [it[0], it[1]] }
          .set { flye_inputs }
      }
      if (params.ont) {
        ont_reads.set { flye_inputs }
        if (params.genome_size == null && params.jellyfish) {
          params.genome_size = genomescope_out
        }
      }
      // Run flye
      FLYE(flye_inputs, params.flye_mode)
      FLYE.out.fasta.set { ch_assembly }
    }
    if (params.assembler == "hifiasm") {
      // HiFi and ONT reads in ultralong mode
      if (params.hifi && params.ont) {
        hifi_reads
          .join(ont_reads)
          .set { hifiasm_inputs }
        HIFIASM(hifiasm_inputs, [[], [], []], [[], [], []])
        GFA_2_FA(HIFIASM.out.processed_contigs)
        GFA_2_FA.out.set { ch_assembly }
      }
      // ONT reads only
      if (!params.hifi && params.ont) {
        ont_reads
          .map { meta, ontreads -> [meta, ontreads, []] }
          .set { hifiasm_inputs }
        HIFIASM_ONT(hifiasm_inputs, [[], [], []], [[], [], []])
        GFA_2_FA(HIFIASM_ONT.out.processed_contigs)
        GFA_2_FA.out.set { ch_assembly }
      }
      // HiFI reads only 
      if (params.hifi && !params.ont) {
        hifi_reads
          .map { meta, ontreads -> [meta, ontreads, []] }
          .set { hifiasm_inputs }
        HIFIASM(hifiasm_inputs, [[], [], []], [[], [], []])
        GFA_2_FA(HIFIASM.out.processed_contigs)
        GFA_2_FA.out.set { ch_assembly }
      }
    }
    if (params.assembler == "flye_on_hifiasm") {
      // Run hifiasm
      hifi_reads
        .map { meta, hifireads -> [meta, hifireads, [] ] }
        .set { hifiasm_inputs }
      HIFIASM(hifiasm_inputs, [[], [], []], [[], [], []])
      GFA_2_FA(HIFIASM.out.processed_contigs)

      // Run flye
      ont_reads.set { flye_inputs }
      if (params.genome_size == null && params.jellyfish) {
        params.genome_size = genomescope_out
      }
      FLYE(flye_inputs, params.flye_mode)

      FLYE.out.fasta
        .join(
          GFA_2_FA.out
        )
        .set { ragtag_in }

      RAGTAG_SCAFFOLD(ragtag_in)
      // takes: meta, assembly (flye), reference (hifi)
      RAGTAG_SCAFFOLD.out.corrected_assembly.set { ch_assembly }
    }
  }
  /*
    Prepare alignments
    */
  if (params.skip_alignments) {
    // Sample sheet layout when skipping assembly and mapping
    // sample,ontreads,assembly,ref_fasta,ref_gff,assembly_bam,assembly_bai,ref_bam
    ch_input
      .map { row -> [row.meta, row.ref_bam] }
      .set { ch_ref_bam }

    ch_input
      .map { row -> [row.meta, row.assembly_bam] }
      .set { ch_assembly_bam }

    ch_input
      .map { row -> [row.meta, row.assembly_bam, row.assembly_bai] }
      .set { ch_assembly_bam_bai }
  }
  else {
    Channel.empty().set { ch_ref_bam }
    if (params.assembler == "flye") {
      flye_inputs
        .map { it -> [it[0], it[1]] }
        .set { longreads }
    }
    if (params.assembler == "hifiasm" || params.assembler == "flye_on_hifiasm") {
      hifiasm_inputs.set { longreads }
      // When using either hifiasm_ont or flye_on_hifiasm, both reads are available, which should be used for qc?
      if (params.hifi && params.ont) {
        if (!params.qc_reads) {
          error("Please specify which reads should be used for qc: 'ONT' or 'HIFI'")
        }
        if (params.qc_reads == 'ONT') {
          ont_reads
            .map { it -> [it[0], it[1]] }
            .set { longreads }
        }
        if (params.qc_reads == 'HIFI') {
          hifi_reads
            .map { it -> [it[0], it[1]] }
            .set { longreads }
        }
      }
    }
    if (params.quast) {

      if (params.use_ref) {
        MAP_TO_REF(longreads, ch_refs)

        MAP_TO_REF.out.set { ch_ref_bam }
      }

      MAP_TO_ASSEMBLY(longreads, ch_assembly)
      MAP_TO_ASSEMBLY.out.aln_to_assembly_bam.set { ch_assembly_bam }

      MAP_TO_ASSEMBLY.out.aln_to_assembly_bam_bai.set { ch_assembly_bam_bai }
      RUN_QUAST(ch_assembly, ch_input, ch_ref_bam, ch_assembly_bam)
      RUN_QUAST.out.quast_tsv.set { assembly_quast_reports }
    }
  }
  /*
    QC on initial assembly
    */
  if (params.busco) {
    RUN_BUSCO(ch_assembly)
    RUN_BUSCO.out.batch_summary.set { assembly_busco_reports }
  }

  if (params.short_reads) {
    MERQURY_QC(ch_assembly, meryl_kmers)
    MERQURY_QC.out.stats
      .join(
        MERQURY_QC.out.spectra_asm_hist
      )
      .join(
        MERQURY_QC.out.spectra_cn_hist
      )
      .join(
        MERQURY_QC.out.assembly_qv
      )
      .set { assembly_merqury_reports }
  }

  if (params.lift_annotations) {
    RUN_LIFTOFF(ch_assembly, ch_input)
  }

  assembly = ch_assembly
  ref_bam = ch_ref_bam

  emit:
  assembly
  ref_bam
  longreads
  assembly_quast_reports
  assembly_busco_reports
  assembly_merqury_reports
}
