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
                single: it.strategy == "single"
                hybrid: it.strategy == "hybrid"
                scaffold: it.strategy == "scaffold"
            }
            .set { ch_main_assemble_branched }

    // Flye inputs:
    ch_main_assemble_branched
        .single
        .filter { it -> it.assembler1 == "flye" || it.assembler2 == "flye" }
        .mix(
            ch_main_assemble_branched
                .scaffold
                .filter { it -> it.assembler1 == "flye" || it.assembler2 == "flye" }
        )
        .set { ch_main_assemble_flye }

    // Assembly flye branch
    ch_main_assemble_flye
        .multiMap {
            it ->
            reads: [
                [
                    id: it.meta.id,
                    genome_size: it.genome_size,
                    flye_args: it.flye_args ?: ""
                ],
                it.assembler1 == "flye" ? it.ontreads : (it.assembler2 == "flye" ? it.hifireads : []),
            ]
            mode: it.assembler1 == "flye" ? "--nano-hq" : "--pacbio-hifi"
        }
        .set { flye_inputs }

    FLYE(flye_inputs.reads, flye_inputs.mode)

    ch_versions = ch_versions.mix(FLYE.out.versions)


    // Hifiasm: everything that is not ONT
    ch_main_assemble_branched
            .single
            .filter { it -> it.assembler1 == "hifiasm" && !it.ontreads }
            .mix(
                ch_main_assemble_branched
                    .hybrid
                    .filter { it -> it.assembler1 == "hifiasm" }
            )
            .mix(ch_main_assemble_branched
                    .scaffold
                    .filter { it -> it.assembler2 == "hifiasm"  }
                    // the samples for scaffolding should not have ONT reads, otherwise hifiasm will run in --ul mode
                    .map { it -> it - it.subMap("ontreads") }
            )
            .set { ch_main_assemble_hifi_hifiasm }

        HIFIASM(ch_main_assemble_hifi_hifiasm
                    .map {
                        it -> [
                            [id: it.meta.id, hifiasm_args: it.hifiasm_args ?: ""],
                            it.hifireads,
                            (it.stragtegy == "hybrid" && it.ontreads) ? it.ontreads : []
                            ]
                        },
                [[], [], []],
                [[], [], []],
                [[], []])

        GFA_2_FA_HIFI( HIFIASM.out.processed_unitigs.map { meta, fasta -> [[id: meta.id], fasta] } )

        ch_versions = ch_versions.mix(HIFIASM.out.versions).mix(GFA_2_FA_HIFI.out.versions)


        // Assemble hifiasm_ont branch
        ch_main_assemble_branched
            .single
            .filter { it -> it.assembler1 == "hifiasm" && it.ontreads }
            .mix(ch_main_assemble_branched
                    .scaffold
                    .filter { it -> it.assembler1 == "hifiasm"  }
            )
            .set { ch_main_assemble_ont_hifiasm }

        HIFIASM_ONT(ch_main_assemble_ont_hifiasm.map { it -> [ [id: it.meta.id, hifiasm_args: it.hifiasm_args ?: ""],  it.ontreads, [] ] }, [[], [], []], [[], [], []], [[], []])

        GFA_2_FA_ONT( HIFIASM_ONT.out.processed_unitigs.map { meta, fasta -> [[id: meta.id], fasta] } )

        ch_versions = ch_versions.mix(HIFIASM_ONT.out.versions).mix(GFA_2_FA_ONT.out.versions)


        // Now, the individual assemblies need to be correctly added into the main channel.
        // This should be done per-strategy I think
        // join assembler outputs back to assembler inputs and determine correct placement of the assembly.
        // Flye:
        ch_main_assemble_flye
            // Convert to list for join
            .map { it -> it.collect { entry -> [ entry.value, entry ] } }
            .join( FLYE.out.fasta
                    .map { meta, assembly -> [meta: [id: meta.id], flye_assembly: assembly ] }
                    .map { it -> it.collect { entry -> [ entry.value, entry ] } }
            )
            // After joining re-create the maps from the stored map
            .map { it -> it.collect { _entry, map -> [ (map.key): map.value ] }.collectEntries() }
            .map { it -> it - it.subMap("flye_assembly") +
                    [
                        assembly:  it.strategy == "single" ? it.flye_assembly : null,
                        assembly1: it.assembler1 == "flye" ? it.flye_assembly : null,
                        assembly2: it.assembler2 == "flye" ? it.flye_assembly : null,
                    ]
            }
            .set { flye_assemblies }

        ch_main_assemble_hifi_hifiasm
            // Convert to list for join
            .map { it -> it.collect { entry -> [ entry.value, entry ] } }
            .join( GFA_2_FA_HIFI.out.contigs_fasta
                    .map { meta, assembly -> [meta: meta, hifiasm_assembly: assembly ] }
                    .map { it -> it.collect { entry -> [ entry.value, entry ] } }
            )
            // After joining re-create the maps from the stored map
            .map { it -> it.collect { _entry, map -> [ (map.key): map.value ] }.collectEntries() }
            .map {
                it -> it -it.subMap("hifiasm_assembly") +
                [
                    assembly: (it.strategy == "single" || it.strategy == "hybrid") && it.assembler1 == "hifiasm" ? it.hifiasm_assembly : null,
                    assembly1: it.strategy == "scaffold" && it.assembler1 == "hifiasm" ? it.hifiasm_assembly : null,
                    assembly2: it.strategy == "scaffold" && it.assembler2 == "hifiasm" ? it.hifiasm_assembly : null
                ]
            }
            .set { hifiasm_hifi_assemblies }


        ch_main_assemble_ont_hifiasm
            .map { it -> it.collect { entry -> [ entry.value, entry ] } }
            .join( GFA_2_FA_ONT.out.contigs_fasta
                    .map { meta, assembly -> [meta: meta, hifiasm_assembly: assembly ] }
                    .map { it -> it.collect { entry -> [ entry.value, entry ] } }
            )
            // After joining re-create the maps from the stored map
            .map { it -> it.collect { _entry, map -> [ (map.key): map.value ] }.collectEntries() }
            .map {
                it -> it -it.subMap("hifiasm_assembly") +
                [
                    assembly: (it.strategy == "single" || it.strategy == "hybrid") && it.assembler1 == "hifiasm" ? it.hifiasm_assembly : null,
                    assembly1: it.strategy == "scaffold" && it.assembler1 == "hifiasm" ? it.hifiasm_assembly : null,
                    assembly2: it.strategy == "scaffold" && it.assembler2 == "hifiasm" ? it.hifiasm_assembly : null
                ]
            }
            .set { hifiasm_ont_assemblies }

        // The single and hybrid channels can be mixed and forwarded.
        // The scaffold channel needs to be joined separately.
        flye_assemblies
            .filter { it -> ["single","hybrid"].contains(it.strategy) }
            .mix(
                hifiasm_hifi_assemblies
                    .filter { it -> ["single","hybrid"].contains(it.strategy) }
            )
            .mix(
                hifiasm_ont_assemblies
                    .filter { it -> ["single","hybrid"].contains(it.strategy) }
            )
            .set { ch_assemblies_no_scaffold }

        // This leaves the scaffold strategy.
        // scaffolds can be: FLYE-HIFIASM, FLYE-FLYE, HIFIASM-HIFIASM HIFIASM-FLYE or
        flye_assemblies
            // Flye-hifiasm
            .filter { it -> it.strategy == "scaffold" && it.assembler1 == "flye" && it.assembler2 == "hifiasm" }
            .map { it -> it.collect { entry -> [ entry.value, entry ] } }
            .join( hifiasm_hifi_assemblies
                    .filter{ it -> it.strategy == "scaffold" && it.assembler1 == "flye" && it.assembler2 == "hifiasm" }
                    .map { it -> [ meta: it.meta, hifiasm_assembly: it.assembly2 ] }
                    .map { it -> it.collect { entry -> [ entry.value, entry ] } }
            )
            .map { it -> it.collect { _entry, map -> [ (map.key): map.value ] }.collectEntries() }
            .map { it -> it - it.subMap("hifiasm_assembly","assembly2") + [assembly2: it.hifiasm_assembly] }
            .set{ scaffold_flye_hifiasm }

        // flye-flye
        flye_assemblies
            .filter { it -> it.strategy == "scaffold" && it.assembler1 == "flye" && it.assembler2 == "flye" }
            .map { it -> it.collect { entry -> [ entry.value, entry ] } }
            .join( flye_assemblies
                    .filter{ it -> it.strategy == "scaffold" && it.assembler1 == "flye" && it.assembler2 == "flye" }
                    .map { it -> [ meta: it.meta, flye_assembly: it.assembly2 ] }
                    .map { it -> it.collect { entry -> [ entry.value, entry ] } }
            )
            .map { it -> it.collect { _entry, map -> [ (map.key): map.value ] }.collectEntries() }
            .map { it -> it - it.subMap("flye_assembly","assembly2") + [assembly2: it.flye_assembly] }
            .set{ scaffold_flye_flye }

        // hifiasm_flye
        hifiasm_ont_assemblies
            .filter { it -> it.strategy == "scaffold" && it.assembler1 == "hifiasm" && it.assembler2 == "flye" }
            .map { it -> it.collect { entry -> [ entry.value, entry ] } }
            .join( flye_assemblies
                    .filter{ it -> it.strategy == "scaffold" && it.assembler1 == "hifiasm" && it.assembler2 == "flye" }
                    .map { it -> [ meta: it.meta, flye_assembly: it.assembly2 ] }
                    .map { it -> it.collect { entry -> [ entry.value, entry ] } }
            )
            .map { it -> it.collect { _entry, map -> [ (map.key): map.value ] }.collectEntries() }
            .map { it -> it - it.subMap("flye_assembly","assembly2") + [assembly2: it.flye_assembly] }
            .set{ scaffold_hifiasm_flye }

        // hifiasm_hifiasm
        hifiasm_ont_assemblies
            .filter { it -> it.strategy == "scaffold" && it.assembler1 == "hifiasm" && it.assembler2 == "hifiasm" }
            .map { it -> it.collect { entry -> [ entry.value, entry ] } }
            .join( hifiasm_hifi_assemblies
                    .filter{ it -> it.strategy == "scaffold" && it.assembler1 == "hifiasm" && it.assembler2 == "hifiasm" }
                    .map { it -> [ meta: it.meta, hifiasm_assembly: it.assembly2 ] }
                    .map { it -> it.collect { entry -> [ entry.value, entry ] } }
            )
            .map { it -> it.collect { _entry, map -> [ (map.key): map.value ] }.collectEntries() }
            .map { it -> it - it.subMap("hifiasm_assembly","assembly2") + [assembly2: it.hifiasm_assembly] }
            .set{ scaffold_hifiasm_hifiasm }

        // branch to scaffold those assemblies that need it
        scaffold_flye_hifiasm
            .mix(scaffold_flye_flye)
            .mix(scaffold_hifiasm_flye)
            .mix(scaffold_hifiasm_hifiasm)
            .set { ch_to_scaffold }

        ch_to_scaffold
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

        ch_to_scaffold
            .map { it -> it - it.subMap("assembly") }
            .map { it -> it.collect { entry -> [ entry.value, entry ] } }
            .join(
                RAGTAG_PATCH.out.patch_fasta
                    .map { it -> [meta: it[0], assembly: it[1]] }
                    .map { it -> it.collect { entry -> [ entry.value, entry ] } }
            )
            .map { it -> it.collect { _entry, map -> [ (map.key): map.value ] }.collectEntries() }
            .set { ch_assemblies_scaffold }

        ch_assemblies_no_scaffold
            .mix(ch_assemblies_scaffold)
            .set { ch_main_assembled }


    ch_versions = ch_versions.mix(RAGTAG_PATCH.out.versions)

    ch_main_branched
        .no_assemble
        .mix( ch_main_assembled )
        .set { ch_main_to_mapping }

    //ch_main_to_mapping.view { it -> "TO MAPPING: $it"}

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
        .map {
            it ->
            [ [id: it.meta.id, qc_reads: it.qc_reads], it.qc_reads_path, it.ref_fasta ]
        }
        .set { map_to_ref_in }

    MAP_TO_REF(map_to_ref_in) // returns meta: [id]

    ch_ref_mapping_branched
        .to_map
        .map { it -> it - it.subMap("ref_map_bam") }
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
