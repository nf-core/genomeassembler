
/* Generic assembly workflow
new params:     params.assembler -> switch between "flye" and "hifiasm" and "flye_on_hifiasm"
                qc_reads  -> "ONT" or 'HIFI' to decide which reads to use for QC with HIFIASM_UL or "flye_on_hifiasm"
renamed params: skip_flye   ->  skip_assembly
                hifi_ont    ->  hifiasm_ont
*/ 

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

    if(params.skip_assembly ) { // CHANGE: PARAM renamed: skip_flye -> skip_assembly
      // Sample sheet layout when skipping assembly
      // sample,ontreads,assembly,ref_fasta,ref_gff
      ch_input
        .map { row -> [row.sample, row.assembly] }
        .set { ch_assembly }
    } 
    if(!params.skip_assembly ) {
      // Somewhat hacky approach to use hifi reads with flye
      if(params.hifi_only && params.assembler == "flye") {
        hifi_reads
          .set { ont_reads }
      }
      if(!params.genome_size == null) {
        ont_reads
          .map { it -> [it[0], it[1], params.genome_size] }
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
        if(params.hifiasm_ont) { // CHANGE: PARAM renamed: hifi_ont -> hifiasm_ont
           hifi_reads
            .join(ont_reads) 
            .set { hifiasm_in }
          HIFIASM_UL(hifiasm_inputs, params.hifi_args)
          HIFIASM_UL
            .out
            .primary_contigs_fasta
            .set { ch_assembly }
        } else {      
          HIFIASM(hifi_reads, params.hifi_args)
          HIFIASM
            .out
            .primary_contigs_fasta
            .set { ch_assembly }
        }
      }
      if(params.assembler == "flye_on_hifiasm") {
        // Run flye
        FLYE(flye_inputs, params.flye_mode)
        HIFIASM(hifi_reads, params.hifi_args)

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
      // Sample sheet layout when skipping FLYE and mapping
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
        if(params.hifiasm_ont || params.assembler == "flye_on_hifiasm") { // CHANGE: NEW PARAM: qc_reads
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

  emit: 
    ch_assembly
    ch_ref_bam
}