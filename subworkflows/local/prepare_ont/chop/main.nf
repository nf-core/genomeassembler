include { PORECHOP_PORECHOP as PORECHOP } from '../../../../modules/nf-core/porechop/porechop/main'

workflow CHOP {
    take:
    input

    main:
    Channel.empty().set { chopped_reads }
    Channel.empty().set { ch_versions }

    if (params.porechop) {
        input.map {
            it ->
            [
                meta: it.meta,
                reads: it.ontreads
            ]
        }
        .set { in_reads }
        PORECHOP(in_reads)
        input.map {
            it ->
            it - it.subMap('ontreads')
        }
        .join(
            PORECHOP.out.reads
                .map { it ->
                    [
                        meta: it[0],
                        ont_reads: it[1]
                    ]
                }
            )
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
