include { QUAST } from '../../../modules/quast/main'

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
    if(params.quast) {
      inputs
        .map { row -> [row.sample, row.ref_fasta, row.ref_gff] }
        .set { inputs_references }

      assembly
        .join(inputs_references)
        .join(aln_to_ref)
        .join(aln_to_assembly)
        .set { quast_in }
      /*
       * Run QUAST
       */
      QUAST(quast_in, use_gff = params.use_ref, use_fasta = false)
    }
}