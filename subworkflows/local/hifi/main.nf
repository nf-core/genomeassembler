include { PREPARE_HIFI } from '../prepare_hifi/main'
include { KMER_LONGREADS as KMER_HIFI } from '../../../modules/yak/main'
include { KMER_HISTOGRAM  } from '../../../modules/yak/main'
include { READ_QV } from '../../../modules/yak/main'

workflow HIFI {
    takes: inputs

    main: 
        PREPARE_HIFI(inputs)
        PREPARE_HIFI
            .out
            .set { hifi_reads }
        KMER_HIFI(hifi_reads)
        KMER_HIFI
            .out
            .set { hifi_kmers }
        KMER_HISTOGRAM(hifi_kmers)
        if(params.short_reads) READ_QV(hifi_kmers.join(yak_kmers))
    
    emit:
        hifi_reads
        hifi_kmers
} 