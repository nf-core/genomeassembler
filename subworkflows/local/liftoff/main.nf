include { LIFTOFF } from '../../../modules/nf-core/liftoff/main'

workflow RUN_LIFTOFF {
    take:
    assembly
    inputs

    main:
    Channel.empty().set { ch_versions }
    assembly
        .join(
            inputs.map { row -> [row.meta, row.ref_fasta, row.ref_gff] }
        )
        .set { liftoff_in }

    LIFTOFF(liftoff_in, [])

    LIFTOFF.out.gff3.set { lifted_annotations }

    versions = ch_versions.mix(LIFTOFF.out.versions)
    emit:
    lifted_annotations
    versions
}
