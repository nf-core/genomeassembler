include { FLYE } from '../../modules/flye/main'    
include { HIFIASM; HIFIASM_UL } from '../../modules/hifiasm/main'
include { MAP_TO_ASSEMBLY } from '../mapping/map_to_assembly/main'
include { MAP_TO_REF } from '../mapping/map_to_ref/main'
include { RUN_QUAST } from '../qc/quast/main'
include { RUN_BUSCO } from '../qc/busco/main'
include { YAK_QC } from '../qc/yak/main'
include { RUN_LIFTOFF } from '../liftoff/main'

workflow ASSEMBLE {
  take: 
    ont_reads // meta, reads
    hifi_reads // meta, reads
    ch_input
    genomescope_out
    shortread_kmers
    
  main:
    // References
    Channel.empty().set { ch_refs }

    if (params.use_ref) {
      ch_input
        .map { row -> [row.sample, row.ref_fasta] }
        .set { ch_refs }
    }

    if(params.skip_assembly ) { 
      // Sample sheet layout when skipping assembly
      // sample,ontreads,assembly,ref_fasta,ref_gff
      ch_input
        .map { row -> [row.sample, row.assembly] }
        .set { ch_assembly }
    } 
    if(!params.skip_assembly ) {
      def hifi_only = (params.hifi && !params.ont) ? true : false
      // Somewhat hacky approach to use hifi reads with flye
      if(params.hifi && params.assembler == "flye") {
        if(!hifi_only) error 'Cannot combine hifi and ont reads with'
        hifi_reads
          .set { ont_reads }
      }
      if(!params.genome_size == null) {
        ont_reads
          .combine(params.genome_size)
          .set { flye_inputs }
      }
      if(params.genome_size == null) {
        ont_reads
          .join(genomescope_out)
          .set { flye_inputs }
      } 
      // CHANGE: new param: assembler 
      if(params.assembler == "flye") {
        // Run flye
        FLYE(flye_inputs, params.flye_mode)
        FLYE
          .out
          .fasta
          .set { ch_assembly }
      } 
      if(params.assembler == "hifiasm") {
        if(params.hifiasm_ont) {
           hifi_reads
            .join(ont_reads) 
            .set { hifiasm_inputs }
          HIFIASM_UL(hifiasm_inputs, params.hifiasm_args)
          HIFIASM_UL
            .out
            .primary_contigs_fasta
            .set { ch_assembly }
        } else {      
          hifi_reads
            .set { hifiasm_inputs }
          HIFIASM(hifiasm_inputs, params.hifiasm_args)
          HIFIASM
            .out
            .primary_contigs_fasta
            .set { ch_assembly }
        }
      }
      if(params.assembler == "flye_on_hifiasm") {
        // Run flye
        FLYE(flye_inputs, params.flye_mode)
        HIFIASM(hifi_reads, params.hifiasm_args)

        FLYE
          .out
          .fasta
          .join(
            HIFIASM
              .out
              .primary_contigs_fasta)
          .set { ragtag_in }
        
        RAGTAG_SCAFFOLD(ragtag_in)  // takes: meta, assembly (flye), reference (hifi)
        RAGTAG_SCAFFOLD
          .out
          .corrected_assembly
          .set { ch_assembly }
      } 
    }
    /*
    Prepare alignments
    */
    if(params.skip_alignments) {
      // Sample sheet layout when skipping assembly and mapping
      // sample,ontreads,assembly,ref_fasta,ref_gff,assembly_bam,assembly_bai,ref_bam
      ch_input
        .map { row -> [row.sample, row.ref_bam] }
        .set { ch_ref_bam }

      ch_input
        .map { row -> [row.sample, row.assembly_bam] }
        .set { ch_assembly_bam }

      ch_input
        .map { row -> [row.sample, row.assembly_bam, row.assembly_bai] }
        .set { ch_assembly_bam_bai } 

    } else {
      Channel.empty().set { ch_ref_bam }
      if(params.assembler == "flye") {
        flye_inputs
          .map { it -> [it[0], it[1]] }
          .set { longreads }
      }
      if(params.assembler == "hifiasm" || params.assembler == "flye_on_hifiasm") {
        hifiasm_inputs
          .set { longreads }
        // When using either hifiasm_ont or flye_on_hifiasm, both reads are available, which should be used for qc?
        if(params.hifiasm_ont || params.assembler == "flye_on_hifiasm" || (params.hifi && params.ont)) { // CHANGE: NEW PARAM: qc_reads
          if(!params.qc_reads) error "Please specify which reads should be used for qc: 'ONT' or 'HIFI'"
          if(params.qc_reads == 'ONT') {
            flye_inputs
              .map { it -> [it[0], it[1]] }
              .set { longreads }
          }
          if(params.qc_reads == 'HIFI') {
            hifiasm_inputs
              .map { it -> [it[0], it[1]] }
              .set { longreads }
          }
        }
      }
      if(params.use_ref) {
        MAP_TO_REF(longreads, ch_refs)

        MAP_TO_REF
          .out
          .set { ch_ref_bam }
      }

      MAP_TO_ASSEMBLY(longreads, ch_assembly)
      MAP_TO_ASSEMBLY
        .out
        .aln_to_assembly_bam
        .set { ch_assembly_bam }

      MAP_TO_ASSEMBLY
        .out
        .aln_to_assembly_bam_bai
        .set { ch_assembly_bam_bai }
    }
    /*
    QC on initial assembly
    */
    YAK_QC(ch_assembly, shortread_kmers)

    RUN_QUAST(ch_assembly, ch_input, ch_ref_bam, ch_assembly_bam)

    RUN_BUSCO(ch_assembly)

    if(params.lift_annotations) {
      RUN_LIFTOFF(ch_assembly, ch_input)
    }
    assembly = ch_assembly
    ref_bam = ch_ref_bam
  emit: 
    assembly
    ref_bam
    longreads
}
