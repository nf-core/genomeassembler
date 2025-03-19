include { PREPARE_ONT } from '../prepare_ont/main'
include { JELLYFISH } from '../jellyfish/main'

workflow ONT {
    take:
    input_channel
    genome_size

    main:
    Channel.empty().set { ch_versions }
    Channel.of([[],[]])
        .tap { genomescope_summary }
        .tap { genomescope_plot }

    PREPARE_ONT(input_channel)

    PREPARE_ONT.out.trimmed.set { ont_reads }

    PREPARE_ONT.out.nanoq_report.set { nanoq_report }

    PREPARE_ONT.out.nanoq_stats.set { nanoq_stats }

    ch_versions = ch_versions.mix(PREPARE_ONT.out.versions)

    if (params.jellyfish) {
        JELLYFISH(PREPARE_ONT.out.trimmed, PREPARE_ONT.out.med_len)
        if (params.genome_size == null) {
            JELLYFISH.out.hap_len.set { genome_size }
        }
        JELLYFISH.out.genomescope_summary.set { genomescope_summary }
        JELLYFISH.out.genomescope_plot.set { genomescope_plot }
        ch_versions = ch_versions.mix(JELLYFISH.out.versions)
    }

    versions = ch_versions

    emit:
    ont_reads
    genome_size
    nanoq_report
    nanoq_stats
    genomescope_plot
    genomescope_summary
    versions
}
