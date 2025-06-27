include { FLYE } from '../../../modules/nf-core/flye/main'
include { HIFIASM } from '../../../modules/nf-core/hifiasm/main'
include { HIFIASM as HIFIASM_ONT } from '../../../modules/nf-core/hifiasm/main'
include { GFA_2_FA as GFA_2_FA_HIFI } from '../../../modules/local/gfa2fa/main'
include { GFA_2_FA as GFA_2_FA_ONT} from '../../../modules/local/gfa2fa/main'
include { MAP_TO_REF } from '../mapping/map_to_ref/main'
include { RUN_LIFTOFF } from '../liftoff/main'
include { RAGTAG_PATCH } from '../../../modules/nf-core/ragtag/patch/main'
include { QC } from '../qc/main'


workflow ASSEMBLE {
    take:
    ch_main
    ch_main
    meryl_kmers

    main:
    // Empty channels
    Channel.empty().set { ch_refs }
    Channel.empty().set { ch_ref_bam }
    Channel.empty().set { ch_assembly_bam }
    Channel.empty().set { ch_assembly }
    Channel.empty().set { flye_inputs }
    Channel.empty().set { hifiasm_inputs }
    Channel.empty().set { longreads }
    Channel.empty().set { ch_versions }

    if (params.use_ref) {
        ch_main
        ch_main
            .map { row -> [row.meta, row.ref_fasta] }
            .set { ch_refs }
    }

    if (params.skip_assembly) {
        // Sample sheet layout when skipping assembly
        // sample,ontreads,assembly,ref_fasta,ref_gff
        ch_main
        ch_main
            .map { row -> [row.meta, row.assembly] }
            .set { ch_assembly }
    }
    if (!params.skip_assembly) {

        ch_main
            .branch { it ->
                hifiasm: (it.strategy == "single" && it.assembler1 == "hifiasm")
                        || (it.strategy == "scaffold" && (it.assembler1 == "hifiasm" || it.assembler2 == "hifiasm"))
                        || (it.strategy == "hybrid" && it.assembler1 == "hifiasm")
                hifiasm_ont: (it.strategy == "single" && it.assembler1 == "hifiasm" && it.ontreads)
                flye: (it.strategy == "single" && it.assembler1 == "flye") || (it.strategy == "scaffold" && (it.assembler1 == "flye"))
            }
        .set { ch_main_branched }

        // Assembly flye branch

        ch_main_branched.flye
            .multiMap {
                it ->
                reads: [
                    [
                        meta: it.meta,
                        genome_size: it.genome_size
                    ],
                    it.ontreads ?: it.hifireads,
                ]
                mode: it.ontreads ? "nano-hq" : "--pacbio-hifi"
            }
            .set { flye_inputs }

            FLYE(flye_inputs.reads, flye_inputs.mode)


        ch_main
            .branch { it ->
                hifiasm: (it.strategy == "single" && it.assembler1 == "hifiasm")
                        || (it.strategy == "scaffold" && (it.assembler1 == "hifiasm" || it.assembler2 == "hifiasm"))
                        || (it.strategy == "hybrid" && it.assembler1 == "hifiasm")
                hifiasm_ont: (it.strategy == "single" && it.assembler1 == "hifiasm" && it.ontreads)
                flye: (it.strategy == "single" && it.assembler1 == "flye") || (it.strategy == "scaffold" && (it.assembler1 == "flye"))
            }
        .set { ch_main_branched }

        // Assembly flye branch

        ch_main_branched.flye
            .multiMap {
                it ->
                reads: [
                    [
                        meta: it.meta,
                        genome_size: it.genome_size
                    ],
                    it.ontreads ?: it.hifireads,
                ]
                mode: it.ontreads ? "nano-hq" : "--pacbio-hifi"
            }
            .set { flye_inputs }

            FLYE(flye_inputs.reads, flye_inputs.mode)

            ch_versions = ch_versions.mix(FLYE.out.versions)

            // Assembly hifiasm branch

            ch_main_branched.hifiasm
                .map { it -> [ it.meta, it.hifireads, it.ontreads ?: [] ] }
                .set { hifiasm_inputs }


            HIFIASM(hifiasm_inputs, [[], [], []], [[], [], []], [[], []])

            GFA_2_FA_HIFI(HIFIASM.out.processed_unitigs)

            ch_versions = ch_versions.mix(HIFIASM.out.versions).mix(GFA_2_FA_HIFI.out.versions)

            // Assemble hifiasm_ont branch
            ch_main_branched.hifiasm_ont
                    .map { it -> [it.meta, it.ontreads, []] }
                    .set { hifiasm_ont_inputs }

            HIFIASM_ONT(hifiasm_ont_inputs, [[], [], []], [[], [], []], [[], []])

            GFA_2_FA_ONT(HIFIASM_ONT.out.processed_unitigs)

            ch_versions = ch_versions.mix(HIFIASM_ONT.out.versions).mix(GFA_2_FA_ONT.out.versions)

            // Create a channel containing all assemblies in a "wide" format
            ch_main
                .map { it -> [meta: it.meta] }
                .join(FLYE.out.fasta
                    .map { it -> [meta: it[0], flye_assembly: it[1]] })
                .join(GFA_2_FA_HIFI.out.contigs_fasta
                    .map { it -> [meta: it[0], hifiasm_hifi_assembly: it[1]]})
                .join(GFA_2_FA_ONT.out.contigs_fasta
                    .map { it -> [meta: it[0], hifiasm_ont_assembly: it[1]]})
                .set { ch_assemblies }

            // Now figure out which of the wide assemblies goes into which generic assembly slot
            ch_main
                .join { ch_assemblies }
                // The extra columns are joined and removed via submap
                .map {
                    it ->å
                    it
                        .subMap('flye_assembly')
                        .subMap('hifiasm_hifi_assembly')
                        .subMap('hifiasm_ont_assembly') +
                        [
                            assembly:  it.strategy == "single" || it.strategy == "hybrid" ?
                                            (it.flye_assembly ?:
                                            it.hifiasm_hifi_assembly ?:
                                            it.hifiasm_ont_assembly) :
                                            null,
                                        // remaining case is "scaffold"
                                        // by definition assembly1 == ONT in "scaffold"
                            assembly1:  it.strategy != "scaffold" ?
                                            null :
                                            it.assembler1 == "flye" ?
                                            (it.flye_assembly) :
                                            (it.hifiasm_ont_assembly),
                            // assembly2 only exists if the strategy is "scaffold"
                            assembly2:  it.strategy != "scaffold" ?
                                            null :
                                            // by definition assembly2 == hifi in "scaffold"
                                            it.assembler2 == "flye" ?
                                                (it.flye_assembly) :
                                                (it.hifiasm_hifi_assembly)
                        ]
                }
                // This should return the unbranched main channel
                .set { ch_main }

            ch_main
                .filter { it ->
                    it.strategy == "scaffold"
                }
                .multiMap {
                    it ->
                    target: [
                        it.meta,
                        it.assembly_scaffolding == "ont_on_hifi" ? (it.assembly1) : (it.assembly2)
                        ]
                    query: [
                        it.meta,
                        it.assembly_scaffolding == "ont_on_hifi" ? (it.assembly2) : (it.assembly1)
                        ]
                }
                .set { ragtag_in }

            RAGTAG_PATCH(ragtag_in.target, ragtag_in.query, [[], []], [[], []] )

            ch_versions = ch_versions.mix(RAGTAG_PATCH.out.versions)

            ch_main
                .join(
                    RAGTAG_PATCH.out.patch_fasta
                        .map { it -> [meta: it[0], assembly_patched: it[1]] }
                )
                .map { it ->
                    it.subMap("assembly_patched") +
                    [
                        assembly: it.strategy == "scaffold" ?
                                    (it.assembly_patched) :
                                    (it.assembly)
                    ]}
    }
    /*
    Prepare alignments
    */
    if (params.skip_alignments) {
        // Sample sheet layout when skipping assembly and mapping
        // sample,ontreads,assembly,ref_fasta,ref_gff,assembly_bam,assembly_bai,ref_bam
        ch_main
            .map { row -> [row.meta, row.ref_bam] }
            .set { ch_ref_bam }

        ch_main
            .map { row -> [row.meta, row.assembly_bam] }
            .set { ch_assembly_bam }
    }
    else {
        Channel.empty().set { ch_ref_bam }

        ch_main
            .map { it ->
                [
                    meta: it.meta,
                    longreads: params.qc_reads == "ont" ? (it.ontreads) : (it.hifireads)
                ]
            }


        if (params.quast) {
            if (params.use_ref) {
                MAP_TO_REF(longreads, ch_refs)
                ch_main
                    .join(
                        MAP_TO_REF.out.ch_aln_to_ref_bam
                            .map { it -> [meta: it[0], ref_map_bam: it[1]] }
                    )
                    .set { ch_main }
            } else {
                ch_main
                    .join(
                        ch_main
                            .map { it -> [meta: it.meta, ref_map_bam: []] }
                    )
                    .set { ch_main }
            }
        }
    }
    /*
    QC on initial assembly
    */
    QC( ch_main,
        meryl_kmers)
    ch_versions = ch_versions.mix(QC.out.versions)

    if (params.lift_annotations) {
        RUN_LIFTOFF(ch_main)
        ch_versions = ch_versions.mix(RUN_LIFTOFF.out.versions)
    }

    emit:
    assembly                    = ch_assembly
    ref_bam                     = ch_ref_bam
    longreads
    assembly_quast_reports      = QC.out.quast_out
    assembly_busco_reports      = QC.out.busco_out
    assembly_merqury_reports    = QC.out.merqury_report_files
    versions                    = ch_versions
}
