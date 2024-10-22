include { TRIMGALORE } from '../../../modules/nf-core/trimgalore/main'
include { MERYL_COUNT } from '../../../modules/nf-core/meryl/count/main'
include { KMER_SHORTREADS } from '../../../modules/local/yak/main'
include { KMER_HISTOGRAM } from '../../../modules/local/yak/main'

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
        shortreads = [ meta, [ file(row.shortread_F) ] ]
    } else {
        if (!file(row.shortread_R).exists()) {
            exit 1, "ERROR: shortread_R fastq file does not exist!\n${row.shortread_R}"
        }
        shortreads = [ meta, [ file(row.shortread_F), file(row.shortread_R) ] ]
    }
    return shortreads
}

workflow PREPARE_SHORTREADS {
  
    take: input_channel
    
    main:
    input_channel
        .map { create_shortread_channel(it) }
        .set { shortreads }
    if(params.trim_short_reads) {
      TRIMGALORE(shortreads)
      TRIMGALORE
        .out
        .reads
        .set { shortreads }
      
    }
    MERYL_COUNT(shortreads.map { it -> [it[0], it[2]] }, params.meryl_k)
    MERYL_COUNT
      .out
      .set { meryl_kmers }
    KMER_SHORTREADS(shortreads)
    KMER_SHORTREADS
      .out
      .set { yak_kmers }
    KMER_HISTOGRAM(yak_kmers)

  emit:
    shortreads
    meryl_kmers
    yak_kmers
}