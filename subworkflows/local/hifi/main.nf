include { PREPARE_HIFI } from '../prepare_hifi/main'


workflow HIFI {
    take: inputs

    main: 
        Channel.empty().set { hifi_kmers }
        Channel.empty().set { hifi_qv }
        PREPARE_HIFI(inputs)
        PREPARE_HIFI
            .out
            .set { hifi_reads }
    
    emit:
        hifi_reads
        hifi_kmers
        hifi_qv
} 