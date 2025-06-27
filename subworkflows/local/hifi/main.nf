include { PREPARE_HIFI } from '../prepare_hifi/main'


workflow HIFI {
    take:
    main_in

    main:
    Channel.empty().set { ch_versions }

    PREPARE_HIFI(main_in)

    ch_versions.mix(PREPARE_HIFI.out.versions)

    versions = ch_versions

    emit:
    main_out = PREPARE_HIFI.out.main_out
    versions
}
