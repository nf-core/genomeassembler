include { LIFTOFF } from '../../../modules/nf-core/liftoff/main'

workflow RUN_LIFTOFF {
    take:
    liftoff_in

    main:
    LIFTOFF(liftoff_in, [])

    lifted_annotations = LIFTOFF.out.gff3

    emit:
    lifted_annotations
}
