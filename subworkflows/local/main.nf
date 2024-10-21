/*
 ===========================================
 * Import subworkflows
 ===========================================
 */
// Read preparation
include { PREPARE_ONT } from './prepare_ont/main'
include { PREPARE_HIFI } from './prepare_hifi/main'
include { JELLYFISH } from './jellyfish/main'

// Read analysis
include { ONT } from './ont/main'
include { HIFI } from './hifi/main'

// Mapping
include { MAP_TO_REF  } from './mapping/map_to_ref/main'
include { MAP_TO_ASSEMBLY  } from './mapping/map_to_assembly/main'
include { MAP_SR } from './mapping/map_sr/main'

// Assembly 
include { ASSEMBLE } from './assemble/main'

// Polishing
include { POLISH } from './polishing/main'
include { POLISH_MEDAKA } from './polishing/medaka/polish_medaka/main'
include { POLISH_PILON } from './polishing/pilon/polish_pilon/main'

// Scaffolding
include { SCAFFOLD } from './scaffolding/main'
include { RUN_RAGTAG } from './scaffolding/ragtag/main'
include { RUN_LINKS } from './scaffolding/links/main'
include { RUN_LONGSTITCH } from './scaffolding/longstitch/main'

// Annotation
include { RUN_LIFTOFF } from './liftoff/main'

// Quality control
include { RUN_QUAST } from './qc/quast/main'
include { RUN_BUSCO } from './qc/busco/main'
include { YAK_QC } from './qc/yak/main'


workflow GENOMEASSEMBLER {
    /*
    Define channels
    */

    Channel.empty().set { ch_input }
    Channel.empty().set { ch_refs }
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
    Check samplesheet
    */

    if(params.samplesheet) {
        Channel.fromPath(params.samplesheet) 
            .splitCsv(header:true) 
            .set { ch_input }
        if(params.use_ref) {
            ch_input
                .map { row -> [row.sample, row.ref_fasta] }
                .set { ch_refs }
      }
    } else {
        exit 1, 'Input samplesheet not specified!'
    }

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
    Assembly
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
    Polishing
    */

    POLISH(ch_input, ch_ont_reads, ch_longreads, ch_shortreads, ch_polished_genome, ch_ref_bam, yak_kmers, meryl_kmers)
    POLISH
      .out
      .set { ch_polished_genome }

    /*
    Scaffolding
    */
    
    SCAFFOLD(ch_input, ch_longreads, ch_polished_genome, ch_refs, ch_ref_bam, yak_kmers, meryl_kmers)

    /*
    The End
    */
}   