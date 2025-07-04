include { BUSCO_BUSCO as BUSCO } from '../../../../modules/nf-core/busco/busco/main'

workflow RUN_BUSCO {
    take:
    ch_main

    main:
    Channel.empty().set { versions }
    Channel.empty().set { batch_summary }
    Channel.empty().set { short_summary_txt }
    Channel.empty().set { short_summary_json }

    ch_main
        .filter {
            it -> it.busco
        }
        .multiMap { it ->
                fasta: [
                    it.meta,
                    it.qc_target
                ]
                busco_lineage: it.busco_lineage
                busco_db: it.busco_db ? file(it.busco_db, checkIfExists: true) : []
            }
        .set { busco_in }

    BUSCO(busco_in.fasta, 'genome', busco_in.busco_lineage, busco_in.busco_db , [], true)
    BUSCO.out.batch_summary.set { batch_summary }
    BUSCO.out.short_summaries_txt.set { short_summary_txt }
    BUSCO.out.short_summaries_json.set { short_summary_json }
    BUSCO.out.versions.set { versions }

    emit:
    batch_summary
    short_summary_json
    short_summary_txt
    versions
}
