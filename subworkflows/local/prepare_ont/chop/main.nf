include { PORECHOP_PORECHOP as PORECHOP } from '../../../../modules/nf-core/porechop/porechop/main'

workflow CHOP {
    take:
    input

    main:
    Channel.empty().set { chopped_reads }
    Channel.empty().set { ch_versions }

    PORECHOP(input)

    PORECHOP.out.reads
        .set { chopped_reads }

        ch_versions.mix(PORECHOP.out.versions)
    }
    else {
        input.set { chopped_reads }
    }
    versions = ch_versions

    emit:
    chopped_reads
    versions
}
