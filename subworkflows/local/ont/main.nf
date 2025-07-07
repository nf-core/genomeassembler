include { PREPARE_ONT } from '../prepare_ont/main'
include { JELLYFISH } from '../jellyfish/main'

workflow ONT {
    take:
    main_in

    main:
    Channel.empty().set { ch_versions }
    Channel.of([[],[]])
        .tap { genomescope_summary }
        .tap { genomescope_plot }

    PREPARE_ONT(main_in)

    PREPARE_ONT.out.main_out.set { ch_main_prepared }

    PREPARE_ONT.out.nanoq_report.set { nanoq_report }

    PREPARE_ONT.out.nanoq_stats.set { nanoq_stats }

    ch_versions = ch_versions.mix(PREPARE_ONT.out.versions)

    //ch_main_prepared.view { it -> "PREPARED: $it"}

    ch_main_prepared
        .branch {
            it ->
            jellyfish: it.ont_jellyfish
            no_jelly: !it.ont_jellyfish
        }

    .set { ch_main_jellyfish_branched }

    JELLYFISH(ch_main_jellyfish_branched.jellyfish)

    ch_main_jellyfish_branched.no_jelly
        .mix( JELLYFISH.out.main_out )
        .set { main_out }

    JELLYFISH.out.genomescope_summary.set { genomescope_summary }
    JELLYFISH.out.genomescope_plot.set { genomescope_plot }
    ch_versions = ch_versions.mix(JELLYFISH.out.versions)

    versions = ch_versions

    emit:
    main_out
    nanoq_report
    nanoq_stats
    genomescope_plot
    genomescope_summary
    versions
}
