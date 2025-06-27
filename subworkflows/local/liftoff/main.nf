include { LIFTOFF } from '../../../modules/nf-core/liftoff/main'

workflow RUN_LIFTOFF {
    take:
    ch_main

    main:
    Channel.empty().set { ch_versions }
    ch_main
        .map { it ->
            [
                it.meta,
                it.assembly,
                it.ref_fasta,
                it.ref_gff
            ]
        }
        .set { liftoff_in }

    LIFTOFF(liftoff_in, [])

    LIFTOFF.out.gff3.set { lifted_annotations }

    versions = ch_versions.mix(LIFTOFF.out.versions)
    emit:
    lifted_annotations
    versions
}
