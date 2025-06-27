include { MAP_TO_ASSEMBLY } from '../mapping/map_to_assembly/main'
include { RUN_BUSCO } from './busco/main.nf'
include { RUN_QUAST } from './quast/main.nf'
include { MERQURY_QC } from './merqury/main.nf'

workflow QC {
    take:
    ch_main
    meryl_kmers

    main:
    Channel.empty().set { ch_versions }
    Channel.empty().set { quast_out }
    Channel.empty().set { busco_out }
    Channel.empty().set { merqury_report_files }

    ch_main
        .map { it -> [meta: it.meta, scaffolds: it.assembly] }
        .set { scaffolds }


    ch_main
        .map { it ->
            [
                meta: it.meta,
                longreads: params.qc_reads == "ont" ? (it.ontreads) : (it.hifireads)
            ]
        }
        .set { reads }

    if (params.quast) {
        MAP_TO_ASSEMBLY(reads, scaffolds)
        ch_main
            .join(
                MAP_TO_ASSEMBLY.out.aln_to_assembly_bam
                    .map { it -> [meta: it[0], assembly_map_bam: it[1]] }
            )
            .set { ch_main }
        ch_versions = ch_versions.mix(MAP_TO_ASSEMBLY.out.versions)
    }

    RUN_QUAST(ch_main)
    RUN_QUAST.out.quast_tsv.set { quast_out }

    ch_versions = ch_versions.mix(RUN_QUAST.out.versions)

    RUN_BUSCO(scaffolds)
    RUN_BUSCO.out.batch_summary.set { busco_out }

    ch_versions = ch_versions.mix(RUN_BUSCO.out.versions)

    if (params.short_reads) {
        MERQURY_QC(scaffolds, meryl_kmers)
        MERQURY_QC.out.stats
            .join(
                MERQURY_QC.out.spectra_asm_hist
            )
            .join(
                MERQURY_QC.out.spectra_cn_hist
            )
            .join(
                MERQURY_QC.out.assembly_qv
            )
            .set { merqury_report_files }

        ch_versions = ch_versions.mix(MERQURY_QC.out.versions)
    }

    versions = ch_versions

    emit:
    quast_out
    busco_out
    merqury_report_files
    versions
}
