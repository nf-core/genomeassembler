include { MAP_TO_ASSEMBLY } from '../mapping/map_to_assembly/main'
include { RUN_BUSCO } from './busco/main.nf'
include { RUN_QUAST } from './quast/main.nf'
include { MERQURY_QC } from './merqury/main.nf'

workflow QC {
    take:
    ch_main // pipeline main
    scaffolds // scaffolds to run qc on
    meryl_kmers // short-read kmers

    main:
    Channel.empty().set { ch_versions }
    Channel.empty().set { quast_out }
    Channel.empty().set { busco_out }
    Channel.empty().set { merqury_report_files }

    ch_main
        .branch {
            it ->
            shortread: it.use_short_reads
            no_shortread: !it.use_short_reads
        }
        .set { ch_shortread_branched }

    ch_shortread_branched
        .shortread
        .map { it -> [it.meta] }
        .join(scaffolds)
        .join(meryl_kmers)
        .multiMap { it ->
                scaffolds: [it[0], it[1]]
                kmers: [it[0], it[2]]
            }
        .set { merqury_in }

    MERQURY_QC(merqury_in.scaffolds, merqury_in._kmers)

    // Make sure that Polish and Scaffold main channels do not contain assembly_map_bam

    ch_main
        .branch {
            it ->
            map_to_assembly: it.quast && !it.assembly_map_bam
            no_map_to_assembly: !it.quast || (it.quast && it.assembly_map_bam)
        }
        .set { ch_map_branched }

    ch_map_branched
        .map_to_assembly
        .map {
            it -> [it.meta, it.qc_reads]
        }
        .join(scaffolds)
        .multiMap {
            meta, reads, target_scaffolds ->
            reads: [meta, reads]
            scaffolds: [meta, target_scaffolds]
        }
        .set { map_assembly_in }

     MAP_TO_ASSEMBLY(map_assembly_in.reads, map_assembly_in.scaffolds)

     // create main channel with mappings
     ch_map_branched
        .map_to_assembly
        .map { it -> it - it.subMap("assembly_map_bam") }
        .map { it -> it.collect { entry -> [ entry.value, entry ] } }
        .join(
            MAP_TO_ASSEMBLY.out.aln_to_assembly_bam
                .map { it -> [meta: it[0], assembly_map_bam: it[1]] }
                .map { it -> it.collect { entry -> [ entry.value, entry ] } }
        )
        .map { it -> it.collect { _entry, map -> [ (map.key): map.value ] }.collectEntries() }
        .mix { ch_map_branched.no_map_to_assembly }
        .map { it -> it.collect { entry -> [ entry.value, entry ] } }
        .join(
            scaffolds
                .map {
                    it -> [meta: it[0], qc_target: it[1] ]
                }
                .map { it -> it.collect { entry -> [ entry.value, entry ] } }
        )
        .map { it -> it.collect { _entry, map -> [ (map.key): map.value ] }.collectEntries() }
        .set { ch_qc }


    ch_versions = ch_versions.mix(MAP_TO_ASSEMBLY.out.versions)

    RUN_QUAST(ch_qc)
    RUN_QUAST.out.quast_tsv.set { quast_out }

    ch_versions = ch_versions.mix(RUN_QUAST.out.versions)

    RUN_BUSCO(ch_qc)
    RUN_BUSCO.out.batch_summary.set { busco_out }

    ch_versions = ch_versions.mix(RUN_BUSCO.out.versions)

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

    emit:
    ch_main     // QC does not (and should not) modify ch_main but returns the input.
    quast_out
    busco_out
    merqury_report_files
    versions = ch_versions
}
