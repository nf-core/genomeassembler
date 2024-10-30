include { MERQURY_MERQURY as MERQURY } from '../../../../modules/local/merqury/merqury/main'

workflow MERQURY_QC {
    take:
        assembly
        meryl_out
    
    main:
        meryl_out
            .map { it -> [[id: it[0].id], it[1]]}
            .join(assembly)
            .set { merqury_in }
        MERQURY(merqury_in)
}

