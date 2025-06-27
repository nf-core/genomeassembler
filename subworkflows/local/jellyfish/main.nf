include { COUNT } from '../../../modules/local/jellyfish/count/main'
include { DUMP } from '../../../modules/local/jellyfish/dump/main'
include { HISTO } from '../../../modules/local/jellyfish/histo/main'
include { STATS } from '../../../modules/local/jellyfish/stats/main'
include { GENOMESCOPE } from '../../../modules/local/genomescope/main'

workflow JELLYFISH {
    take:
    inputs
    nanoq_out

    main:
    Channel.empty().set { genomescope_in }
    Channel.empty().set { ch_versions }
    inputs.map {
        it ->
            [
                meta: it.meta,
                reads: it.ontreads
            ]
        }
    .set { samples }
    COUNT(samples)
    COUNT.out.kmers.set { kmers }

    ch_versions = ch_versions.mix(COUNT.out.versions)

    if (params.dump) {
        DUMP(kmers)
        ch_versions = ch_versions.mix(DUMP.out.versions)
    }

    HISTO(kmers)
    ch_versions = ch_versions.mix(HISTO.out.versions)

    if (!params.read_length == null) {
        HISTO.out.histo
        .map {
            it ->
                [
                    it[0],
                    it[1],
                    params.kmer_length,
                    params.read_length
                ]
            }
            .set { genomescope_in }
    }

    if (params.read_length == null) {
        HISTO.out.histo
        .map {
            it ->
                [
                    it[0],
                    it[1],
                    params.kmer_length
                ]
        }
        .join(nanoq_out)
        .set { genomescope_in }
    }

    GENOMESCOPE(genomescope_in)

    ch_versions = ch_versions.mix(GENOMESCOPE.out.versions)

    STATS(kmers)

    ch_versions = ch_versions.mix(STATS.out.versions)

    inputs
        .map {
            it -> it.subMap('genome_size')
        }
        .join(
            GENOMESCOPE.out.estimated_hap_len
                .map {
                    it ->
                    [
                        meta: it[0],
                        genome_size: it[1]
                    ]
                }
        )
        .set { outputs }

    GENOMESCOPE.out.summary.set { genomescope_summary }

    GENOMESCOPE.out.plot.set { genomescope_plot }

    versions = ch_versions

    emit:
    outputs
    genomescope_summary
    genomescope_plot
    versions
}
