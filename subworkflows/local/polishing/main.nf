include { POLISH_MEDAKA } from './medaka/polish_medaka/main.nf'
include { POLISH_PILON } from './pilon/polish_pilon/main.nf'
include { POLISH_DORADO } from './dorado/main.nf'

workflow POLISH {
    take:
    ch_main
    meryl_kmers

    main:
    polish_busco_reports = channel.empty()
    polish_quast_reports = channel.empty()
    polish_merqury_reports = channel.empty()

    ch_main_polish = ch_main
        .branch { it ->
            def medaka_polishers = ["medaka","medaka+pilon"]
            def dorado_polishers = ["dorado","dorado+pilon"]
            medaka: medaka_polishers.contains(it.meta.polish)
            dorado: dorado_polishers.contains(it.meta.polish)
            no_ont_polish: !medaka_polishers.contains(it.meta.polish) && !dorado_polishers.contains(it.meta.polish)
        }

    POLISH_MEDAKA(ch_main_polish.medaka, meryl_kmers)

    POLISH_DORADO(ch_main_polish.dorado, meryl_kmers)

    polish_busco_reports = POLISH_MEDAKA.out.busco_out
        .mix(POLISH_DORADO.out.busco_out)


    polish_quast_reports = POLISH_MEDAKA.out.quast_out
        .mix(POLISH_DORADO.out.quast_out)

    polish_merqury_reports = POLISH_MEDAKA.out.merqury_report_files
        .mix(POLISH_DORADO.out.merqury_report_files)

    ch_main_polish_pilon = POLISH_MEDAKA.out.ch_main
        .mix(POLISH_DORADO.out.ch_main)
        .mix(ch_main_polish.no_ont_polish)

    /*
    Polishing with short reads using pilon
    */

    ch_main_polish_pilon_in = ch_main_polish_pilon
        .branch {
            it ->
            def pilon_polishers = ["pilon","medaka+pilon", "dorado+pilon"]
            pilon: pilon_polishers.contains(it.meta.polish)
            no_pilon: true
        }

    POLISH_PILON(ch_main_polish_pilon_in.pilon, meryl_kmers)

    ch_out = ch_main_polish_pilon_in.no_pilon
        .mix(POLISH_PILON.out.ch_main)

    polish_busco_reports = polish_busco_reports
        .concat(
            POLISH_PILON.out.busco_out
        )

    polish_quast_reports = polish_quast_reports
        .concat(
            POLISH_PILON.out.quast_out
        )

    polish_merqury_reports = polish_merqury_reports
        .concat(
            POLISH_PILON.out.merqury_report_files
        )

    emit:
    ch_main = ch_out
    polish_busco_reports
    polish_quast_reports
    polish_merqury_reports
}
