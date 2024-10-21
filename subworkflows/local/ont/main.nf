include { PREPARE_ONT } from '../prepare_ont/main'
include { JELLYFISH }   from '../jellyfish/jellyfish'
include { KMER_LONGREADS as KMER_ONT } from '../../../modules/yak/main'
include { KMER_HISTOGRAM  } from '../../../modules/yak/main'
include { READ_QV } from '../modules/yak/main'


workflow ONT {
    take: 
        input_channel
        yak_kmers

    main:
    genome_size = Channel.empty()

    PREPARE_ONT(input_channel)
    JELLYFISH(PREPARE_ONT.out.trimmed, PREPARE_ONT.out.med_len)
    if(params.genome_size == null) {
        JELLYFISH
            .out
            .hap_len
            .set { genome_size }
    }
    PREPARE_ONT
        .out
        .trimmed
        .set { ont_reads }
    KMER_ONT(ont_reads)
    KMER_ONT
        .out
        .set { ont_kmers }
    KMER_HISTOGRAM(ont_kmers)
    if(params.short_reads) READ_QV(ont_kmers.join(yak_kmers))
    
    emit:
     genome_size
     ont_reads
     ont_kmers
}