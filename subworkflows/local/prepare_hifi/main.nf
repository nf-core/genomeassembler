include { LIMA } from '../../../modules/nf-core/lima/main'
include { SAMTOOLS_FASTQ as TO_FASTQ } from '../../../modules/nf-core/samtools/fastq/main'

workflow PREPARE_HIFI {
    take:
    main_in

    main:
    Channel.empty().set { ch_versions }

    main_in
        .branch {
            hifi: it.hifireads
            no_hifi: !it.hifireads
        }
        .set {ch_main_hifi_branched }


    ch_main_hifi_branched
        .hifi
        .branch {
            lima: it.hifi_trim
            no_lima: !it.hifi_trim
        }
        .set { ch_hifi_trim_branched }


    // lima channel goes through lima and to_fastq
    ch_hifi_trim_branched
        .lima
        .multiMap {
            it ->
            reads: [it.meta, it.hifireads]
            primers: it.hifi_primers
        }
        .set { ch_lima_in }

    LIMA(ch_lima_in.reads, ch_lima_in.primers )
    TO_FASTQ(LIMA.out.bam, false)

    // no_lima is mixed with lima outputs
    ch_hifi_trim_branched
        .no_lima
        .mix(
            // lima inputs are joined to lima outputs
            ch_hifi_trim_branched
                .lima
                .map { it -> it - it.subMap('hifireads') }
                .map { it -> it.collect { entry -> [ entry.value, entry ] } }
                .join(
                    TO_FASTQ.out.fastq
                    .map {
                        it ->
                            [
                                meta: it[0],
                                hifireads: it[1]
                            ]
                        }
                    .map { it -> it.collect { entry -> [ entry.value, entry ] } }
                    )
                .map { it -> it.collect { _entry, map -> [ (map.key): map.value ] }.collectEntries() }
            )
        // this contains all hifi samples, mix back with no_hifi and set to main_out
        .mix(ch_main_hifi_branched.no_hifi)
        .set { main_out }

    versions = ch_versions.mix(LIMA.out.versions).mix(TO_FASTQ.out.versions)

    emit:
    main_out
    versions
}
