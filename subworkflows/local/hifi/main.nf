include { PREPARE_HIFI } from '../prepare_hifi/main'


workflow HIFI {
    take:
    inputs

    main:
    Channel.empty().set { ch_versions }

    PREPARE_HIFI(inputs)

    PREPARE_HIFI.out.hifireads.set { hifi_reads }

    ch_versions.mix(PREPARE_HIFI.out.versions)

    versions = ch_versions

    emit:
    hifi_reads
    versions
}
