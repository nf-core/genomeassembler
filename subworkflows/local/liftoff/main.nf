include { LIFTOFF } from '../../../modules/nf-core/liftoff/main'

workflow RUN_LIFTOFF {
    take:
    liftoff_in

    main:
    Channel.empty().set { ch_versions }

    LIFTOFF(liftoff_in, [])

    LIFTOFF.out.gff3.set { lifted_annotations }

    versions = ch_versions.mix(LIFTOFF.out.versions)
    emit:
    lifted_annotations
    versions
}
