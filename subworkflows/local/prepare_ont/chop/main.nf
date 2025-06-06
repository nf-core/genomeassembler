include { PORECHOP_PORECHOP as PORECHOP } from '../../../../modules/nf-core/porechop/porechop/main'

workflow CHOP {
    take:
    in_reads

    main:
    Channel.empty().set { chopped_reads }
    Channel.empty().set { ch_versions }

    if (params.porechop) {
        PORECHOP(in_reads)
        PORECHOP.out.reads.set { chopped_reads }
        ch_versions.mix(PORECHOP.out.versions)
    }
    else {
        in_reads.set { chopped_reads }
    }
    versions = ch_versions

    emit:
    chopped_reads
    versions
}
