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
    meryl_kmers
    genome_size

    main:
    Channel.empty().set { ch_versions }
    Channel.empty().set { links_busco }
    Channel.empty().set { links_quast }
    Channel.empty().set { links_merqury }
    Channel.empty().set { longstitch_busco }
    Channel.empty().set { longstitch_quast }
    Channel.empty().set { longstitch_merqury }
    Channel.empty().set { ragtag_busco }
    Channel.empty().set { ragtag_quast }
    Channel.empty().set { ragtag_merqury }

    if (params.scaffold_links) {
        RUN_LINKS(inputs, in_reads, assembly, references, ch_aln_to_ref, meryl_kmers)
        RUN_LINKS.out.busco_out.set { links_busco }
        RUN_LINKS.out.quast_out.set { links_quast }
        RUN_LINKS.out.merqury_report_files.set { links_merqury }

        ch_versions = ch_versions.mix(RUN_LINKS.out.versions)
    }

    if (params.scaffold_longstitch) {
        RUN_LONGSTITCH(inputs, in_reads, assembly, references, ch_aln_to_ref, meryl_kmers, genome_size)
        RUN_LONGSTITCH.out.busco_out.set { longstitch_busco }
        RUN_LONGSTITCH.out.quast_out.set { longstitch_quast }
        RUN_LONGSTITCH.out.merqury_report_files.set { longstitch_merqury }

        ch_versions = ch_versions.mix(RUN_LONGSTITCH.out.versions)
    }

    if (params.scaffold_ragtag) {
        RUN_RAGTAG(inputs, in_reads, assembly, references, ch_aln_to_ref, meryl_kmers)
        RUN_RAGTAG.out.busco_out.set { ragtag_busco }
        RUN_RAGTAG.out.quast_out.set { ragtag_quast }
        RUN_RAGTAG.out.merqury_report_files.set { ragtag_merqury }

        ch_versions = ch_versions.mix(RUN_RAGTAG.out.versions)
    }

    links_busco
        .concat(longstitch_busco)
        .concat(ragtag_busco)
        .set { scaffold_busco_reports }

    links_quast
        .concat(longstitch_quast)
        .concat(ragtag_quast)
        .set { scaffold_quast_reports }

    links_merqury
        .concat(longstitch_merqury)
        .concat(ragtag_merqury)
        .set { scaffold_merqury_reports }

    versions = ch_versions

    emit:
    scaffold_busco_reports
    scaffold_quast_reports
    scaffold_merqury_reports
    versions
}
