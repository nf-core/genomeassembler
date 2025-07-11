include { MEDAKA_PARALLEL as MEDAKA } from '../../../../../modules/local/medaka/medaka_consensus/main'

workflow RUN_MEDAKA {
    take:
    in_reads
    assembly

    main:

    in_reads
        .join(assembly)
        .set { medaka_in }

    MEDAKA(medaka_in)

    MEDAKA.out.assembly.set { medaka_out }
    MEDAKA.out.versions.set { versions }

    emit:
    medaka_out
    versions
}
