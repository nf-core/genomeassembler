include { POLISH_MEDAKA } from './medaka/polish_medaka/main'
include { POLISH_PILON } from './pilon/polish_pilon/main'

workflow POLISH {
    take:
    ch_main
    meryl_kmers

    main:

    Channel.empty().set { ch_versions }
    Channel.empty().set { polish_busco_reports }
    Channel.empty().set { polish_quast_reports }
    Channel.empty().set { polish_merqury_reports }

    ch_main
        .branch { it ->
            medaka: it.polish_medaka
            no_medaka: !it.polish_medaka
        }
        .set { ch_main }

    POLISH_MEDAKA(ch_main.medaka, meryl_kmers)

    POLISH_MEDAKA.out.ch_main
        .mix { ch_main.no_medaka }
        .set { ch_main }

    POLISH_MEDAKA.out.busco_out.set { polish_busco_reports }

    POLISH_MEDAKA.out.quast_out.set { polish_quast_reports }

    POLISH_MEDAKA.out.merqury_report_files.set { polish_merqury_reports }

    ch_versions = ch_versions.mix(POLISH_MEDAKA.out.versions)

    /*
    Polishing with short reads using pilon
    */

    ch_main
        .branch {
            it ->
            pilon: it.polish_pilon
            no_pilon: !it.polish_pilon
        }
        .set { ch_main }

    POLISH_PILON(ch_main.polish_pilon, meryl_kmers)

    ch_main.no_pilon.mix(POLISH_PILON.out.ch_main)
        .set { ch_main }

    polish_busco_reports
        .concat(
            POLISH_PILON.out.busco_out
        )
        .set { polish_busco_reports }

    polish_quast_reports
        .concat(
            POLISH_PILON.out.quast_out
        )
        .set { polish_quast_reports }

    polish_merqury_reports
        .concat(
            POLISH_PILON.out.merqury_report_files
        )
        .set { polish_merqury_reports }

    ch_versions = ch_versions.mix(POLISH_PILON.out.versions)

    versions = ch_versions

    emit:
    ch_main
    polish_busco_reports
    polish_quast_reports
    polish_merqury_reports
    versions
}
