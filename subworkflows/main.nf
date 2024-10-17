/*
 ===========================================
 * Import processes from modules
 ===========================================
 */
// YAK

include { KMER_LONGREADS as KMER_ONT } from '../modules/yak/main'
include { KMER_LONGREADS as KMER_HIFI } from '../modules/yak/main'
include { KMER_SHORTREADS } from '../modules/yak/main'
include { KMER_HISTOGRAM as KMER_ONT_HIST } from '../modules/yak/main'
include { KMER_HISTOGRAM as KMER_HIFI_HIST} from '../modules/yak/main'
include { KMER_HISTOGRAM as KMER_SR_HIST} from '../modules/yak/main'
include { READ_QV as KMER_ONT_QV } from '../modules/yak/main'
include { READ_QV as KMER_HIFI_QV } from '../modules/yak/main'

include { TRIMGALORE } from '../modules/trimgalore/main'

/*
 ===========================================
 * Import subworkflows
 ===========================================
 */
// Read preparation
include { PREPARE_ONT } from './prepare_ont/main'
include { JELLYFISH } from './jellyfish/main'
include { PREPARE_HIFI } from './prepare_hifi/main'

// Mapping
include { MAP_TO_REF  } from './mapping/map_to_ref/main'
include { MAP_TO_ASSEMBLY  } from './mapping/map_to_assembly/main'
include { MAP_SR } from './mapping/map_sr/main'

// Assembly 
include { ASSEMBLE } from './assemble/main'

// Polishing
include { POLISH_MEDAKA } from './polishing/medaka/polish_medaka/main'
include { POLISH_PILON } from './polishing/pilon/polish_pilon/main'

// Scaffolding
include { RUN_RAGTAG } from './scaffolding/ragtag/main'
include { RUN_LINKS } from './scaffolding/links/main'
include { RUN_LONGSTITCH } from './scaffolding/longstitch/main'

// Annotation
include { RUN_LIFTOFF } from './liftoff/main'

// Quality control
include { RUN_QUAST } from './qc/quast/main'
include { RUN_BUSCO } from './qc/busco/main'
include { YAK_QC } from './qc/yak/main'


 /*
 Accessory function to create input for pilon
 modified from nf-core/rnaseq/subworkflows/local/input_check.nf
 */

def create_shortread_channel(LinkedHashMap row) {
    // create meta map
    def meta = [:]
    meta.id       = row.sample
    meta.paired   = row.paired.toBoolean()

    // add path(s) of the fastq file(s) to the meta map
    def shortreads = []
    if (!file(row.shortread_F).exists()) {
        exit 1, "ERROR: shortread_F fastq file does not exist!\n${row.shortread_F}"
    }
    if (!meta.paired) {
        shortreads = [ meta.id, meta.paired, [ file(row.shortread_F) ] ]
    } else {
        if (!file(row.shortread_R).exists()) {
            exit 1, "ERROR: shortread_R fastq file does not exist!\n${row.shortread_R}"
        }
        shortreads = [ meta.id, meta.paired, [ file(row.shortread_F), file(row.shortread_R) ] ]
    }
    return shortreads
}

workflow GENOME {
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
  Channel.empty().set { ch_shortreads_reads }
  Channel.empty().set { sr_kmers }
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
    ch_input
      .map { create_shortread_channel(it) }
      .set { ch_shortreads }
    if(params.trim_short_reads) {
      TRIMGALORE(ch_shortreads)
      TRIMGALORE
        .out
        .reads
        .set { ch_shortreads }
    }
    KMER_SHORTREADS(ch_shortreads)
    KMER_SHORTREADS
      .out
      .set { sr_kmers }
    KMER_SR_HIST(sr_kmers)
  }
  /*
  ONT reads
  */
  if(params.ont) {
    PREPARE_ONT(ch_input)
    JELLYFISH(PREPARE_ONT.out.trimmed, PREPARE_ONT.out.trimmed_med_len)
    if(params.genome_size == null) {
    JELLYFISH
        .out
        .estimated_hap_len
        .set { genome_size }
  }
    PREPARE_ONT
      .out
      .trimmed
      .set { ch_ont_reads }
    KMER_ONT(ch_ont_reads)
    KMER_ONT
      .out
      .set { ont_kmers }
    KMER_ONT_HIST(ont_kmers)
    if(params.short_reads) KMER_ONT_QV(ont_kmers.join(sr_kmers))
  } 
  /*
  HIFI reads
  */
  if(params.hifi) {
    PREPARE_HIFI(ch_input)
    PREPARE_HIFI
      .out
      .set { ch_hifi_reads }
    KMER_HIFI(ch_hifi_reads)
    KMER_HIFI
      .out
      .set { hifi_kmers }
    KMER_HIFI_HIST(hifi_kmers)
    if(params.short_reads) KMER_HIFI_QV(hifi_kmers.join(sr_kmers))
  }

  /*
  Assembly
  */

  ASSEMBLE(ch_ont_reads, ch_hifi_reads, ch_input, genome_size, sr_kmers)
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
  Polishing with medaka; ONT only
  */

  if(params.polish_medaka) {
    
    if(params.hifi_ont) error 'Medaka should not be used on ONT-HiFi hybrid assemblies'
    if(params.hifi && !params.ont) error 'Medaka should not be used on HiFi assemblies'

    POLISH_MEDAKA(ch_input, PREPARE_ONT.out.trimmed, ch_polished_genome, ch_ref_bam, sr_kmers)

    POLISH_MEDAKA
      .out
      .set { ch_polished_genome }
  }

  /*
  Polishing with short reads using pilon
  */

  if(params.polish_pilon) {
    POLISH_PILON(ch_input, ch_shortreads, ch_longreads, ch_polished_genome, ch_ref_bam, sr_kmers)
    POLISH_PILON
      .out
      .pilon_improved
      .set { ch_polished_genome }
  } 

  /*
  Scaffolding
  */

  if(params.scaffold_ragtag) {
    RUN_RAGTAG(ch_input, ch_longreads, ch_polished_genome, ch_refs, ch_ref_bam, sr_kmers)
  }

  if(params.scaffold_links) {
    RUN_LINKS(ch_input, ch_longreads, ch_polished_genome, ch_refs, ch_ref_bam, sr_kmers)
  }

  if(params.scaffold_longstitch) {
    RUN_LONGSTITCH(ch_input, ch_longreads, ch_polished_genome, ch_refs, ch_ref_bam, sr_kmers)
  }
  
} 