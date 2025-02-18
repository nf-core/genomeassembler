include { PREPARE_HIFI } from '../prepare_hifi/main'


workflow HIFI {
    take:
    inputs

    main:
    Channel.empty().set { hifi_kmers }
    Channel.empty().set { hifi_qv }
    Channel.empty().set { ch_versions }

    PREPARE_HIFI(inputs)

    PREPARE_HIFI.out.set { hifi_reads }

    ch_versions.mix(PREPARE_HIFI.out.versions)

    versions = ch_versions

    emit:
    hifi_reads
    hifi_kmers
    hifi_qv
    versions
}
