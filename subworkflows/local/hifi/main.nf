include { PREPARE_HIFI } from '../prepare_hifi/main'
include { KMER_LONGREADS as KMER_HIFI } from '../../../modules/local/yak/main'
include { KMER_HISTOGRAM  } from '../../../modules/local/yak/main'
include { READ_QV } from '../../../modules/local/yak/main'

workflow HIFI {
    take: inputs

    main: 
        Channel.empty().set { hifi_kmers }
        PREPARE_HIFI(inputs)
        PREPARE_HIFI
            .out
            .set { hifi_reads }
        if(params.yak) {
            KMER_HIFI(hifi_reads)
            KMER_HIFI
                .out
                .set { hifi_kmers }
            KMER_HISTOGRAM(hifi_kmers)
            if(params.short_reads) READ_QV(hifi_kmers.join(yak_kmers))
        }
    
    emit:
        hifi_reads
        hifi_kmers
} 