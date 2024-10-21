include { MERQURY } from '../../../modules/merqury/main'

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

