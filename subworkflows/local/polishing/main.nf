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
            medaka: ["medaka","medaka+pilon"].contains(it.polish)
            no_medaka: !["medaka","medaka+pilon"].contains(it.polish)
        }
        .set { ch_main_polish }

    POLISH_MEDAKA(ch_main_polish.medaka, meryl_kmers)

    POLISH_MEDAKA.out.ch_main
        .mix(ch_main_polish.no_medaka)
        .set { ch_main_polish_pilon }

    POLISH_MEDAKA.out.busco_out.set { polish_busco_reports }

    POLISH_MEDAKA.out.quast_out.set { polish_quast_reports }

    POLISH_MEDAKA.out.merqury_report_files.set { polish_merqury_reports }

    ch_versions = ch_versions.mix(POLISH_MEDAKA.out.versions)

    /*
    Polishing with short reads using pilon
    */

    ch_main_polish_pilon
        .branch {
            it ->
            pilon: ["pilon","medaka+pilon"].contains(it.polish)
            no_pilon: !["pilon","medaka+pilon"].contains(it.polish)
        }
        .set { ch_main_polish_pilon_in }

    POLISH_PILON(ch_main_polish_pilon_in.pilon, meryl_kmers)

    ch_main_polish_pilon_in.no_pilon.mix(POLISH_PILON.out.ch_main)
        .set { ch_out }

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
    ch_main = ch_out
    polish_busco_reports
    polish_quast_reports
    polish_merqury_reports
    versions
}
