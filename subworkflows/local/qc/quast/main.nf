include { QUAST } from '../../../../modules/local/quast/main'

workflow RUN_QUAST {
    take:
    assembly
    inputs
    aln_to_ref
    aln_to_assembly

    main:
    /* prepare for quast:
     * This makes use of the input channel to obtain the reference and reference annotations
     * See quast module for details
     */
    Channel.empty().set { quast_results }
    Channel.empty().set { quast_tsv }

    if (params.quast) {
        inputs
            .map { row -> [row.meta, row.ref_fasta, row.ref_gff] }
            .set { inputs_references }

        assembly
            .join(inputs_references)
            .join(aln_to_ref)
            .join(aln_to_assembly)
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
