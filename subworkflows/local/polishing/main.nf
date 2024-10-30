include { POLISH_MEDAKA } from './medaka/polish_medaka/main'
include { POLISH_PILON } from './pilon/polish_pilon/main'

workflow POLISH {
    take:
        inputs
        ch_ont_reads
        ch_longreads
        ch_shortreads
        ch_polished_genome
        reference_bam
        yak_kmers
        meryl_kmers

    main:
    if(params.polish_medaka) {
    
        if(params.hifiasm_ont) error 'Medaka should not be used on ONT-HiFi hybrid assemblies'
        if(params.hifi && !params.ont) error 'Medaka should not be used on HiFi assemblies'

        POLISH_MEDAKA(inputs, ch_ont_reads, ch_polished_genome, reference_bam, yak_kmers, meryl_kmers)

        POLISH_MEDAKA
            .out
            .set { ch_polished_genome }
    }

    /*
    Polishing with short reads using pilon
    */

    if(params.polish_pilon) {
        POLISH_PILON(inputs, ch_shortreads, ch_longreads, ch_polished_genome, reference_bam, yak_kmers, meryl_kmers)
        POLISH_PILON
            .out
            .pilon_improved
            .set { ch_polished_genome }
    } 

  emit:
    ch_polished_genome
}