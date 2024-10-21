
include { RUN_LINKS } from './links/main'
include { RUN_LONGSTITCH } from './longstitch/main'
include { RUN_RAGTAG } from './ragtag/main'

workflow SCAFFOLD {
    take:
        inputs
        in_reads
        assembly
        references
        ch_aln_to_ref
        yak_kmers
        meryl_kmers

    main:
        if(params.scaffold_links) RUN_LINKS(inputs, in_reads, assembly, references, ch_aln_to_ref, yak_kmers, meryl_kmers)
        if(params.scaffold_longstitch) RUN_LONGSTITCH(inputs, in_reads, assembly, references, ch_aln_to_ref, yak_kmers, meryl_kmers)
        if(params.scaffold_ragtag) RUN_RAGTAG(inputs, in_reads, assembly, references, ch_aln_to_ref, yak_kmers, meryl_kmers)
}