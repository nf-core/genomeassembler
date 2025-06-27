include { QUAST } from '../../../../modules/local/quast/main'

workflow RUN_QUAST {
    take:
    ch_main

    main:
    Channel.empty().set { versions }
    /* prepare for quast:
     * This makes use of the input channel to obtain the reference and reference annotations
     * See quast module for details
     */
    Channel.empty().set { quast_results }
    Channel.empty().set { quast_tsv }

    if (params.quast) {
        ch_main
            .map { it ->
                [
                    it.meta,
                    it.assembly,
                    it.ref_fasta,
                    [],
                    it.reference_map_bam,
                    it.assembly_map_bam
                ]

            }
            .set { quast_in }
        /*
        * Run QUAST
        */
        QUAST(quast_in, params.use_ref, false)
        QUAST.out.results.set { quast_results }
        QUAST.out.tsv.set { quast_tsv }
        QUAST.out.versions.set { versions }
    }

    emit:
    quast_results
    quast_tsv
    versions
}
