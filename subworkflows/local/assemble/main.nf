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
    meryl_kmers

    main:
    // Empty channels
    Channel.empty().set { flye_inputs }
    Channel.empty().set { hifiasm_inputs }
    Channel.empty().set { ch_versions }

    ch_main
        .branch {
            it ->
            to_assemble: !it.assembly
            no_assemble: it.assembly
        }
        .set {
            ch_main_branched
        }

    ch_main_branched
        .to_assemble
        .branch { it ->
            hifiasm: (it.strategy == "single" && it.assembler1 == "hifiasm" && !it.ontreads)
                    || (it.strategy == "scaffold" && (it.assembler1 == "hifiasm" || it.assembler2 == "hifiasm"))
                    || (it.strategy == "hybrid" && it.assembler1 == "hifiasm")
            hifiasm_ont: (it.strategy == "single" && it.assembler1 == "hifiasm" && it.ontreads)
            flye: (it.strategy == "single" && it.assembler1 == "flye") || (it.strategy == "scaffold" && it.assembler1 == "flye")
        }
        .set { ch_main_assemble }

        // Assembly flye branch

    ch_main_assemble
        .flye
        .multiMap {
            it ->
            reads: [
                [
                    id: it.meta.id,
                    genome_size: it.genome_size
                ],
                it.ontreads ?: it.hifireads,
            ]
            mode: it.flye_mode ?: it.ontreads ? "nano-hq" : "--pacbio-hifi"
        }
        .set { flye_inputs }

        FLYE(flye_inputs.reads, flye_inputs.mode)

        ch_versions = ch_versions.mix(FLYE.out.versions)

        // Assembly hifiasm branch
        ch_main_assemble.hifiasm
            .map { it -> [ it.meta, it.hifireads, it.ontreads ?: [] ] }
            .set { hifiasm_inputs }

        HIFIASM(hifiasm_inputs, [[], [], []], [[], [], []], [[], []])

        GFA_2_FA_HIFI(HIFIASM.out.processed_unitigs)

        ch_versions = ch_versions.mix(HIFIASM.out.versions).mix(GFA_2_FA_HIFI.out.versions)
        // Assemble hifiasm_ont branch

        ch_main_assemble.hifiasm_ont
                .map { it -> [it.meta, it.ontreads, []] }
                .set { hifiasm_ont_inputs }

        HIFIASM_ONT(hifiasm_ont_inputs, [[], [], []], [[], [], []], [[], []])

        GFA_2_FA_ONT(HIFIASM_ONT.out.processed_unitigs)

        ch_versions = ch_versions.mix(HIFIASM_ONT.out.versions).mix(GFA_2_FA_ONT.out.versions)

        // Create a channel containing all assemblies in a "wide" format
        ch_main_branched
            .to_assemble
            .map { it -> [it.meta] }
            //FLYE meta map contains id and genomesize
            .join(FLYE.out.fasta.map { meta, assembly -> [[meta.id], assembly ] })
            .join(GFA_2_FA_HIFI.out.contigs_fasta)
            .join(GFA_2_FA_ONT.out.contigs_fasta)
            .map { it -> [meta: it[0], flye_assembly: it[1], hifiasm_hifi_assembly: it[2], hifiasm_ont_assembly: it[3]] }
            .set { ch_assemblies }
        // Now figure out which of the wide assemblies goes into which generic assembly slot
        ch_main_branched.to_assemble
            // Turn map into list for joining:
            // each tuple in the list contains the value(s) and the original map
            // I think this should also work without the entry.value, keeping the map in the tuple
            // but it would required a different collect strategy that seems more involved?
            .map { it -> it.collect { entry -> [ entry.value, entry ] } }
            .join(ch_assemblies
                        .map { it -> it.collect {  entry -> [ entry.value, entry ] } }
            )
            // After joining re-create the maps from the stored map
            .map { it -> it.collect { _entry, map -> [ (map.key): map.value ] }.collectEntries() }
            // The extra columns are joined and removed via submap
            .map { it ->
                    it - it.subMap('flye_assembly', 'hifiasm_hifi_assembly', 'hifiasm_ont_assembly') +
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
            // This should return the to_assemble branch
            .set { ch_main_assembled }

        // branch to scaffold those assemblies that need it
        ch_main_assembled
            .branch { it ->
                scaffold: it.strategy == "scaffold"
                no_scaffold: it.strategy != "scaffold"
            }
            .set { ch_assembled_branch_scaffold }

        ch_assembled_branch_scaffold.scaffold
            .multiMap {
                it ->
                target: [
                    it.meta,
                    it.assembly_scaffolding_order == "ont_on_hifi" ? (it.assembly1) : (it.assembly2)
                    ]
                query: [
                    it.meta,
                    it.assembly_scaffolding_order == "ont_on_hifi" ? (it.assembly2) : (it.assembly1)
                    ]
            }
            .set { ragtag_in }

        RAGTAG_PATCH(ragtag_in.target, ragtag_in.query, [[], []], [[], []] )

        // Add the scaffolded assemblies to the scaffold branch and mix with unscaffolded branch
        // recreates ch_main_assembled (unbranched)
        ch_assembled_branch_scaffold
            .scaffold
            .map { it -> it.collect { entry -> [ entry.value, entry ] } }
            .join(
                RAGTAG_PATCH.out.patch_fasta
                    .map { it -> [meta: it[0], assembly_patched: it[1]] }
                    .map { it -> it.collect { entry -> [ entry.value, entry ] } }
            )
            .map { it -> it.collect { _entry, map -> [ (map.key): map.value ] }.collectEntries() }
            .map { it ->
                it - it.subMap("assembly_patched")  +
                [
                    assembly: it.strategy == "scaffold" ?
                                (it.assembly_patched) :
                                (it.assembly)
                ]
            }
            .mix(ch_assembled_branch_scaffold.no_scaffold)
            .set { ch_main_assembled }


    ch_versions = ch_versions.mix(RAGTAG_PATCH.out.versions)

    ch_main_branched
        .no_assemble
        .mix( ch_main_assembled )
        .set { ch_main_to_mapping }

    ch_main_to_mapping
        .branch {
            it ->
            quast: it.quast
            no_quast: !it.quast
        }
        // Note that this channel is set here but the quast branch is further used
        .set { ch_main_quast_branch }

    ch_main_quast_branch
        .quast
        .branch {
            it ->
                use_ref: it.use_ref
                no_use_ref: !it.use_ref
        }
        .set {
            ch_quast_branched
        }

    ch_quast_branched
        .use_ref
        .branch { it ->
            to_map: !it.ref_map_bam
            dont_map: it.ref_map_bam
        }
        .set { ch_ref_mapping_branched }

    ch_ref_mapping_branched
        .to_map
        .multiMap {
            it ->
            reads: [it.meta, it.qc_reads]
            ref: [it.meta, it.ref_fasta]
        }
        .set {map_to_ref_in}

    MAP_TO_REF(map_to_ref_in.reads, map_to_ref_in.ref)

    ch_ref_mapping_branched
        .to_map
        .map { it -> it - it.subMap["ref_map_bam"] }
        .map { it -> it.collect { entry -> [ entry.value, entry ] } }
        .join(
            MAP_TO_REF.out.ch_aln_to_ref_bam
                .map { it -> [meta: it[0], ref_map_bam: it[1]] }
                .map { it -> it.collect { entry -> [ entry.value, entry ] } }
        )
        .map { it -> it.collect { _entry, map -> [ (map.key): map.value ] }.collectEntries() }
        .mix(ch_ref_mapping_branched.dont_map)
        .mix(ch_quast_branched.no_use_ref)
        // above recreates ch_main_quast_branch.quast
        .mix(ch_main_quast_branch.no_quast)
        .set { ch_main_to_qc }


    //QC on initial assembly


    // scaffolds to QC need to be defined here
    ch_main_to_qc
        .map { it -> [it.meta, it.assembly] }
        .set { scaffolds }


    QC(ch_main_to_qc, scaffolds, meryl_kmers)

    ch_versions = ch_versions.mix(QC.out.versions)

    ch_main_to_qc
        .filter {
            it -> it.lift_annotations
        }
        .map { it ->
            [
                it.meta,
                it.assembly,
                it.ref_fasta,
                it.ref_gff
            ]
        }
        .set { liftoff_in }

    RUN_LIFTOFF(liftoff_in)
    ch_versions = ch_versions.mix(RUN_LIFTOFF.out.versions)

    emit:
    ch_main                     = ch_main_to_qc
    assembly_quast_reports      = QC.out.quast_out
    assembly_busco_reports      = QC.out.busco_out
    assembly_merqury_reports    = QC.out.merqury_report_files
    versions                    = ch_versions
}
