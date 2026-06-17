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
    meryl_kmers

    main:

    Channel.empty().set { ch_versions }
    Channel.empty().set { polish_busco_reports }
    Channel.empty().set { polish_quast_reports }
    Channel.empty().set { polish_merqury_reports }

    if (params.polish_medaka) {

        if (params.hifiasm_ont) {
            error('Medaka should not be used on ONT-HiFi hybrid assemblies')
        }
        if (params.hifi && !params.ont) {
            error('Medaka should not be used on HiFi assemblies')
        }

        POLISH_MEDAKA(inputs, ch_ont_reads, ch_polished_genome, reference_bam, meryl_kmers)

        POLISH_MEDAKA.out.polished_assembly.set { ch_polished_genome }

        POLISH_MEDAKA.out.busco_out.set { polish_busco_reports }

        POLISH_MEDAKA.out.quast_out.set { polish_quast_reports }

        POLISH_MEDAKA.out.merqury_report_files.set { polish_merqury_reports }

        ch_versions = ch_versions.mix(POLISH_MEDAKA.out.versions)
    }

    /*
    Polishing with short reads using pilon
    */

    if (params.polish_pilon) {
        POLISH_PILON(inputs, ch_shortreads, ch_longreads, ch_polished_genome, reference_bam, meryl_kmers)

        POLISH_PILON.out.pilon_polished.set { ch_polished_genome }

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
    }

    versions = ch_versions

    emit:
    ch_polished_genome
    polish_busco_reports
    polish_quast_reports
    polish_merqury_reports
    versions
}
