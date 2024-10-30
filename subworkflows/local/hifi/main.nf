include { PREPARE_HIFI } from '../prepare_hifi/main'
include { YAK_KMER_LONGREADS as YAK_KMER_HIFI } from '../../../modules/local/yak/main'
include { YAK_KMER_HISTOGRAM  } from '../../../modules/local/yak/main'
include { YAK_READ_QV } from '../../../modules/local/yak/main'

workflow HIFI {
    take: inputs

    main: 
        Channel.empty().set { hifi_kmers }
        Channel.empty().set { hifi_qv }
        PREPARE_HIFI(inputs)
        PREPARE_HIFI
            .out
            .set { hifi_reads }
        if(params.yak) {
            YAK_KMER_HIFI(hifi_reads)
            YAK_KMER_HIFI
                .out
                .set { hifi_kmers }
            YAK_KMER_HISTOGRAM(hifi_kmers)
            if(params.short_reads) {
                YAK_READ_QV(hifi_kmers
                            .join(
                                yak_kmers
                                .map { it -> [ [id: it[0].id], it[1] ] }))
                YAK_READ_QV.out.set { hifi_qv }
            }  
        }
    
    emit:
        hifi_reads
        hifi_kmers
        hifi_qv
} 