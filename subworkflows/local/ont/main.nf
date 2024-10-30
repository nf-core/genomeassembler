include { PREPARE_ONT } from '../prepare_ont/main'
include { JELLYFISH }   from '../jellyfish/main'
include { YAK_KMER_LONGREADS as YAK_KMER_ONT } from '../../../modules/local/yak/main'
include { YAK_KMER_HISTOGRAM  } from '../../../modules/local/yak/main'
include { YAK_READ_QV } from '../../../modules/local/yak/main'


workflow ONT {
    take: 
        input_channel
        yak_kmers

    main:
    Channel.empty().set { genome_size }
    Channel.empty().set { ont_kmers }
    Channel.empty().set { ont_qv }

    PREPARE_ONT(input_channel)

    PREPARE_ONT
        .out
        .trimmed
        .set { ont_reads }

    PREPARE_ONT
        .out
        .nanoq_report
        .set { nanoq_report }

    PREPARE_ONT
        .out
        .nanoq_stats
        .set { nanoq_stats }
    

    if(params.jellyfish) {
        JELLYFISH(PREPARE_ONT.out.trimmed, PREPARE_ONT.out.med_len)
        if(params.genome_size == null) {
            JELLYFISH
                .out
                .hap_len
                .set { genome_size }
        }
    }

    if(params.yak) {
        YAK_KMER_ONT(ont_reads)
        YAK_KMER_ONT
            .out
            .set { ont_kmers }
        YAK_KMER_HISTOGRAM(ont_kmers)
        if(params.short_reads) {
            YAK_READ_QV(ont_kmers
                        .join(
                            yak_kmers
                            .map { it -> [ [id: it[0].id], it[1] ] }))
            YAK_READ_QV.out.set { ont_qv }
        }             
    }
    
    emit:
     genome_size
     ont_reads
     ont_kmers
     ont_qv
     nanoq_report
     nanoq_stats
}