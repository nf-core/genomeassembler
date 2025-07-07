include { PORECHOP_PORECHOP as PORECHOP } from '../../../../modules/nf-core/porechop/porechop/main'

workflow CHOP {
    take:
    input

    main:
    Channel.empty().set { chopped_reads }
    Channel.empty().set { ch_versions }

    PORECHOP(input)

    input.map {
            it -> [ it[0] ]

        }
        .join(PORECHOP.out.reads)
        .set { chopped_reads }

    ch_versions.mix(PORECHOP.out.versions)

    versions = ch_versions

    emit:
    chopped_reads
    versions
}
