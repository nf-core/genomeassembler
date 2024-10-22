include { MERQURY_MERQURY as MERQURY } from '../../../../modules/nf-core/merqury/merqury/main'

workflow MERQURY_QC {
    take:
        assembly
        meryl_out
    
    main:
        assembly
            .join(meryl_out)
            .set { merqury_in }
        MERQURY(merqury_in)
}

