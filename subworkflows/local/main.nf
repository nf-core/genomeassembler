/*
 ===========================================
 * Import subworkflows
 ===========================================
 */

// Read preparation
include { PREPARE_SHORTREADS } from './prepare_shortreads/main'
include { ONT } from './ont/main'
include { HIFI } from './hifi/main'

// Assembly 
include { ASSEMBLE } from './assemble/main'

// Polishing
include { POLISH } from './polishing/main'

// Scaffolding
include { SCAFFOLD } from './scaffolding/main'

workflow GENOMEASSEMBLER {
    take:
    ch_input
    ch_refs
    /*
    Define channels
    */
    main:

    Channel.empty().set { ch_ref_bam }
    Channel.empty().set { ch_assembly }
    Channel.empty().set { ch_assembly_bam }
    Channel.empty().set { ch_assembly_bam_bai }
    Channel.empty().set { ch_medaka_in }
    Channel.empty().set { ch_polished_genome }
    Channel.empty().set { ch_ont_reads }
    Channel.empty().set { ch_hifi_reads }
    Channel.empty().set { ch_shortreads }
    Channel.empty().set { yak_kmers }
    Channel.empty().set { meryl_kmers }
    Channel.empty().set { ch_flye_inputs }
    Channel.empty().set { ch_hifiasm_inputs }
    Channel.empty().set { genome_size }

    /*
    =============
    Prepare reads
    =============
    */
    /*
    Short reads
    */
    if(params.short_reads) {
        PREPARE_SHORTREADS(ch_input)
        PREPARE_SHORTREADS
            .out
            .shortreads
            .set { ch_shortreads }
        PREPARE_SHORTREADS
            .out
            .yak_kmers
            .set { yak_kmers }
        PREPARE_SHORTREADS
            .out
            .meryl_kmers
            .set { meryl_kmers }
    }


    /*
    ONT reads
    */
    if(params.ont) {
        ONT(ch_input, yak_kmers)
        ONT
            .out
            .genome_size
            .set { genome_size }
        ONT
            .out
            .ont_reads
            .set { ch_ont_reads }
    } 


    /*
    HIFI reads
    */
    if(params.hifi) {
        HIFI(ch_input)
        HIFI
            .out
            .hifi_reads
            .set { ch_hifi_reads }
    }

    /*
    =============
    Assembly
    =============
    */

    ASSEMBLE(ch_ont_reads, ch_hifi_reads, ch_input, genome_size, yak_kmers, meryl_kmers)
    ASSEMBLE
      .out
      .assembly
      .set { ch_polished_genome }
    ASSEMBLE
      .out
      .ref_bam
      .set { ch_ref_bam }
    ASSEMBLE
      .out
      .longreads
      .set { ch_longreads }
    
    /*
    =============
    Polishing
    =============
    */

    POLISH(ch_input, ch_ont_reads, ch_longreads, ch_shortreads, ch_polished_genome, ch_ref_bam, yak_kmers, meryl_kmers)
    POLISH
      .out
      .set { ch_polished_genome }

    /*
    =============
    Scaffolding
    =============
    */
    
    SCAFFOLD(ch_input, ch_longreads, ch_polished_genome, ch_refs, ch_ref_bam, yak_kmers, meryl_kmers)

    /*
    The End
    */
}   