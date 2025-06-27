include { LIMA } from '../../../modules/nf-core/lima/main'
include { SAMTOOLS_FASTQ as TO_FASTQ } from '../../../modules/nf-core/samtools/fastq/main'

workflow PREPARE_HIFI {
    take:
    main_in

    main:
    Channel.empty().set { ch_versions }
    main_in
        .map { it -> [it.meta, it.hifireads] }
        .set { hifireads }

    if (params.lima) {
        if (!params.pacbio_primers) {
            error('Trimming with lima requires a file containing primers (--pacbio_primers)')
        }
        LIMA(hifireads, params.pacbio_primers)
        TO_FASTQ(LIMA.out.bam, false)
        main_in
            .map { it -> it.subMap('hifireads') }
            .join(
                TO_FASTQ.out.fastq.map {
                    it ->
                        [
                            meta: it[0],
                            hifireads: it[1]
                        ]
                    }
                )
            .set { main_out }
        ch_versions.mix(LIMA.out.versions).mix(TO_FASTQ.out.versions)
    }
    versions = ch_versions

    emit:
    main_out
    versions
}
