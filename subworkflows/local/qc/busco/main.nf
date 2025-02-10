include { BUSCO_BUSCO as BUSCO } from '../../../../modules/nf-core/busco/busco/main'

workflow RUN_BUSCO {
    take:
    assembly

    main:
    Channel.empty().set { batch_summary }
    Channel.empty().set { short_summary_txt }
    Channel.empty().set { short_summary_json }

    if (params.busco) {
        BUSCO(assembly, 'genome', params.busco_lineage, params.busco_db ? file(params.busco_db, checkIfExists: true) : [], [])
        BUSCO.out.batch_summary.set { batch_summary }
        BUSCO.out.short_summaries_txt.set { short_summary_txt }
        BUSCO.out.short_summaries_json.set { short_summary_json }
    }

    emit:
    batch_summary
    short_summary_json
    short_summary_txt
}
