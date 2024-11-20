include { BUSCO_BUSCO as BUSCO } from '../../../../modules/nf-core/busco/busco/main'

workflow RUN_BUSCO {
  take: 
    assembly

  main:
  Channel.empty().set { busco_batch_summary }
  Channel.empty().set { busco_short_summary_txt }
  Channel.empty().set { busco_short_summary_json }

  if(params.busco) {
      BUSCO(assembly, 'genome', params.busco_lineage, params.busco_db ? file( params.busco_db, checkIfExists: true ) : [], [])
      BUSCO
        .out
        .batch_summary
        .set { busco_batch_summary }
      BUSCO
        .out
        .short_summaries_txt
        .set { busco_short_summary_txt }
      BUSCO
        .out
        .short_summaries_json
        .set { busco_short_summary_json }
  }
  
  emit:
    busco_batch_summary
    busco_short_summary_json
    busco_short_summary_txt
}