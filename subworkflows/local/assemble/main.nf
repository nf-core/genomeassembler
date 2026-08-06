include { FLYE as FLYE_ONT} from '../../../modules/nf-core/flye/main'
include { FLYE as FLYE_HIFI} from '../../../modules/nf-core/flye/main'
include { HIFIASM } from '../../../modules/nf-core/hifiasm/main'
include { HIFIASM as HIFIASM_ONT } from '../../../modules/nf-core/hifiasm/main'
include { GFATOOLS_GFA2FA as GFA2FA_HIFI } from '../../../modules/nf-core/gfatools/gfa2fa/main'
include { GFATOOLS_GFA2FA as GFA2FA_ONT  } from '../../../modules/nf-core/gfatools/gfa2fa/main'
include { MAP_TO_REF } from '../mapping/map_to_ref/main'
include { LIFTOFF } from '../../../modules/nf-core/liftoff/main'
include { RAGTAG_PATCH } from '../../../modules/nf-core/ragtag/patch/main'
include { HTSLIB_BGZIPTABIX as BGZIP_HIFI } from '../../../modules/nf-core/htslib/bgziptabix/main'
include { HTSLIB_BGZIPTABIX as BGZIP_ONT } from '../../../modules/nf-core/htslib/bgziptabix/main'
include { HTSLIB_BGZIPTABIX as BGZIP_FLYE_ONT } from '../../../modules/nf-core/htslib/bgziptabix/main'
include { HTSLIB_BGZIPTABIX as BGZIP_FLYE_HIFI } from '../../../modules/nf-core/htslib/bgziptabix/main'
include { HTSLIB_BGZIPTABIX as BGZIP_RAGTAG } from '../../../modules/nf-core/htslib/bgziptabix/main'

include { QC } from '../qc/main'


workflow ASSEMBLE {
    take:
    ch_main
    meryl_kmers

    main:
    /*
    Samples are split into those that need assembly, and those that will not be assembled (i.e. assemblies are provided)
    */
    ch_main.dump(tag: "Assemble - Inputs")

    ch_main_branched = ch_main
        .branch {
            it ->
            to_assemble: !it.meta.assembly
            no_assemble: it.meta.assembly
        }

    /*
    There are three assembly strategies:
        - Single: Using a single assembler with one type of reads
        - Hybrid: Using a single assembler with both types of read in one run (only hifiasm --ul)
        - Scaffold: Separately assembling ONT and HiFi reads, and then scaffolding one onto the other

    Each sample can only have one strategy, and branching happens here.
    */
    ch_main_assemble_branched = ch_main_branched
            .to_assemble
            .branch { it ->
                single: it.meta.strategy == "single"
                hybrid: it.meta.strategy == "hybrid"
                scaffold: it.meta.strategy == "scaffold"
            }

    ch_main_assemble_branched
        .single
        .dump(tag: "Assemble: Branched: Single")
    ch_main_assemble_branched
        .hybrid
        //.view {"Assemble: Hybrid: $it"}
        .dump(tag: "Assemble: Branched: Hybrid")
    ch_main_assemble_branched
        .scaffold
        .dump(tag: "Assemble: Branched: scaffold")

    /*
    =========================
        FLYE ASSEMBLER
    =========================
    */
    /*
    Inputs for flye assembler:
        - Samples with single strategy, where the assembler is flye
        - Samples from the scaffold strategy where either (or both) assembler is flye
    */

    ch_main_assemble_flye = ch_main_assemble_branched
        .single
        .filter { it -> it.meta.assembler_ont == "flye" }
        .mix(
            // Add in the scaffolding samples where flye is used
            ch_main_assemble_branched
                .scaffold
                .filter { it -> it.meta.assembler_ont == "flye" || it.meta.assembler_hifi == "flye"  }
        )

    // Assembly flye branch
    // Extra args per sample are stored in the meta map, so is the estimated / expected genome size
    // The inputs are created once for ONT and once for HiFi
    flye_ont_inputs = ch_main_assemble_flye
        .filter { it -> it.meta.assembler_ont == "flye" && it.meta.ontreads }
        .multiMap {
            it ->
            reads: [
                it.meta,
                it.meta.ontreads ?: [],
            ]
            mode: it.meta.assembler_ont == "flye" ? "--nano-hq" : null
        }

    // These are the hifi samples
    flye_hifi_inputs = ch_main_assemble_flye
        // Those where the hifi assembler is flye, or where there is only one assembler and only hifireads
        .filter { it ->
            it.meta.assembler_hifi == "flye" && it.meta.hifireads ||
            (
                it.meta.strategy == "single" &&
                it.meta.hifireads &&
                !it.meta.ontreads &&
                it.meta.assembler == "flye"
            )
        }
        .multiMap {
            it ->
            reads: [
                it.meta,
                it.meta.hifireads ?: [],
            ]
            mode: it.meta.assembler_hifi == "flye" ? "--pacbio-hifi" : null
        }

    flye_ont_inputs.reads.dump(tag: "Assemble: Flye-ONT inputs")
    flye_hifi_inputs.reads.dump(tag: "Assemble: Flye-HIFI inputs")

    // Run through flye
    FLYE_ONT(flye_ont_inputs.reads, flye_ont_inputs.mode)
    ch_zip_flye_ont = FLYE_ONT.out.fasta.map {
        meta, scaffold ->
        [
            meta,
            scaffold,
            [],
            []
        ]
    }
    BGZIP_FLYE_ONT(ch_zip_flye_ont, "compress", false, "fa")

    FLYE_HIFI(flye_hifi_inputs.reads, flye_hifi_inputs.mode)
    ch_zip_flye_hifi = FLYE_HIFI.out.fasta.map {
        meta, scaffold ->
        [
            meta,
            scaffold,
            [],
            []
        ]
    }
    BGZIP_FLYE_HIFI(ch_zip_flye_hifi, "compress", false, "fa")
    /*
    =========================
        HIFIASM ASSEMBLER
    =========================
    */
    /* Hifiasm: everything that is not hifiasm-ONT
            - Single branch with hifiasm as assembler and no ont reads (only hifireads)
            - Hybrid assembly
            - Scaffold samples where assembler_hifi (hifi assembler) is hifiasm
    */
    //ch_main_assemble_branched.hybrid.view {"ASSEMBLE: Branched: Hybrid"}
    ch_main_assemble_hifi_hifiasm = ch_main_assemble_branched
            .single
            .filter {
                it -> it.meta.assembler_hifi == "hifiasm"
            }
            .mix(
                ch_main_assemble_branched
                    .hybrid
                    .filter {
                        it -> it.meta.assembler_ont == "hifiasm"
                    }
            )
            .mix(ch_main_assemble_branched
                    .scaffold
                    .filter {
                         it -> it.meta.assembler_hifi == "hifiasm"
                    }
            )
            .map {
                    it -> [
                        it.meta,
                        it.meta.hifireads,
                        // for hybrid samples include ONT reads in 3rd slot of first input (see hifiasm module)
                        (it.meta.strategy == "hybrid" && it.meta.ontreads) ? it.meta.ontreads : []
                        ]
                    }

    ch_main_assemble_hifi_hifiasm.dump(tag: "Assemble: hifiasm HIFI inputs")

    //ch_main_assemble_hifi_hifiasm.view { "Assemble: hifiasm HIFI inputs: $it" }

    HIFIASM(ch_main_assemble_hifi_hifiasm,
            [[], [], []],
            [[], [], []],
            [[], []])

    // hifiasm produces GFA files
    GFA2FA_HIFI( HIFIASM.out.primary_contigs )

    ch_zip_hifi = GFA2FA_HIFI.out.fasta.map {
        meta, scaffold ->
        [
            meta,
            scaffold,
            [],
            []
        ]
    }

    BGZIP_HIFI(ch_zip_hifi, "compress", false, "fa")

    /*
    hifiasm with ONLY ont reads.
    Assemble hifiasm_ont branch:
        Single branch with hifiasm and only ont reads
        Scaffold branch where assembler_ont (ont assembler) is hifiasm
    */

    ch_main_assemble_ont_hifiasm = ch_main_assemble_branched
        .single
        .filter { it -> it.meta.assembler_ont == "hifiasm" && it.meta.ontreads }
        .mix(ch_main_assemble_branched
                .scaffold
                .filter { it -> it.meta.assembler_ont == "hifiasm"  }
        )

    ch_main_assemble_ont_hifiasm.dump(tag: "Assemble: hifiasm ONT inputs")

    HIFIASM_ONT(ch_main_assemble_ont_hifiasm.map { it -> [ it.meta,  it.meta.ontreads, [] ] }, [[], [], []], [[], [], []], [[], []])

    GFA2FA_ONT( HIFIASM_ONT.out.primary_contigs)

    ch_zip_ont = GFA2FA_ONT.out.fasta.map {
        meta, scaffold ->
        [
            meta,
            scaffold,
            [],
            []
        ]
    }

    BGZIP_ONT(ch_zip_ont, "compress", false, "fa")

    // Flye:
    flye_assemblies = BGZIP_FLYE_ONT.out.output
        .filter {
            meta, _fasta -> meta.strategy != "scaffold"
        }
        .map { meta_old, assembly -> [meta: meta_old + [ assembly: assembly ] ] }
        .mix(
            BGZIP_FLYE_HIFI.out.output
                .filter {
                    meta, _fasta -> meta.strategy != "scaffold"
                }
                .map { meta_old, assembly -> [meta: meta_old + [ assembly: assembly ] ] }
        )

    flye_assemblies.dump(tag: "Assemble: Flye assemblies")

    // regernerate meta maps
    hifiasm_hifi_assemblies = BGZIP_HIFI.out.output
        .filter { it -> it[0].strategy != "scaffold" }
        .map { meta_old, assembly ->
        [
            meta: meta_old +
            // stick assembly into the correct key
            [
                assembly: (meta_old.strategy == "single" && meta_old.assembler_hifi == "hifiasm")  || (meta_old.strategy == "hybrid" && meta_old.assembler_ont == "hifiasm") ? assembly : null,
            ]
        ]
        }

    hifiasm_hifi_assemblies.dump(tag: "Assemble: hifiasm HIFI assemblies")

    hifiasm_ont_assemblies = BGZIP_ONT.out.output
        .filter { meta, _fasta -> meta.strategy != "scaffold" }
        .map { meta, assembly ->
            [
                meta: meta +
                [
                    assembly: assembly
                ]
            ]
        }

    hifiasm_ont_assemblies.dump(tag: "Assemble: hifiasm ONT assemblies")

    /*
    =========================
          SCAFFOLDING
    =========================
    */

    // The single and hybrid channels can be mixed and forwarded.

    ch_assemblies_no_scaffold = flye_assemblies
        .mix(hifiasm_hifi_assemblies)
        .mix(hifiasm_ont_assemblies)

    ch_assemblies_no_scaffold.dump(tag: "Assemble: Assemblies without scaffolding")


    /*
    -------------------
    Prepare Scaffolding
    -------------------
    */
    // This leaves the scaffold strategy.
    // scaffolds can be: FLYE-HIFIASM, FLYE-FLYE, HIFIASM-HIFIASM or HIFIASM-FLYE
    // The above is (ONT-HIFI)

    scaffold_flye_hifiasm = BGZIP_FLYE_ONT.out.output
        // Flye-hifiasm
        .filter { meta, _fasta ->
            meta.strategy == "scaffold" &&
            meta.assembler_ont == "flye" &&
            meta.assembler_hifi == "hifiasm"
        }
        .map { meta, fasta -> [meta.id, meta, fasta] }
        .join(
            BGZIP_HIFI.out.output
                .filter { meta, _fasta ->
                    meta.strategy == "scaffold" &&
                    meta.assembler_ont == "flye" &&
                    meta.assembler_hifi == "hifiasm"
                }
                .map { meta, fasta -> [ meta.id, fasta ] }
        )
        .map { _id, meta_old, assembly_flye, assembly_hifiasm ->
            [
                meta: meta_old -
                        meta_old.subMap("hifiasm_assembly", "assembly_hifi", "assembly_ont", "flye_assembly") +
                        [
                            assembly_ont: assembly_flye,
                            assembly_hifi: assembly_hifiasm
                        ]
            ]
        }

    // flye-flye
    scaffold_flye_flye = BGZIP_FLYE_ONT.out.output
        .filter {
            meta, _fasta -> meta.strategy == "scaffold" && meta.assembler_ont == "flye" && meta.assembler_hifi == "flye"
        }
        .map {
            meta, fasta -> [meta.id, meta, fasta] // id, meta, ont assembly
        }
        .join(
            BGZIP_FLYE_HIFI.out.output
                .filter {
                    meta, _fasta -> meta.strategy == "scaffold" && meta.assembler_ont == "flye" && meta.assembler_hifi == "flye"
                }
                .map {
                    meta, fasta -> [ meta.id, fasta ] // id, hifi assembly
                },
        )
        .map { _id, meta, ont_assembly, hifi_assembly ->
            [
                meta: meta +
                [
                    assembly_ont: ont_assembly,
                    assembly_hifi: hifi_assembly
                ]
            ]
        }

    // hifiasm_flye
    scaffold_hifiasm_flye = BGZIP_ONT.out.output
        .filter {
            meta, _assembly -> meta.strategy == "scaffold" &&
                meta.assembler_ont == "hifiasm" &&
                meta.assembler_hifi == "flye"
        }
        .map {
            meta, assembly ->
            [
                meta.id,
                meta,
                assembly
            ]
        }
        .join(
            FLYE_HIFI.out.fasta
                .filter{ meta, _fasta -> meta.strategy == "scaffold" && meta.assembler_ont == "hifiasm" && meta.assembler_hifi == "flye" }
                .map { meta, fasta -> [ meta.id, fasta ] }
        )
        .map {
            _id, meta, hifiasm_ont_assembly, flye_hifi_assembly ->
            [
                meta: meta +
                    [
                        assembly_ont: hifiasm_ont_assembly,
                        assembly_hifi: flye_hifi_assembly
                    ]
            ]
        }

    // hifiasm_hifiasm
    scaffold_hifiasm_hifiasm = BGZIP_ONT.out.output
        .filter {
            meta, _assembly -> meta.strategy == "scaffold" &&
                meta.assembler_ont == "hifiasm" &&
                meta.assembler_hifi == "hifiasm"
        }
        .map {
            meta, assembly ->
            [
                meta.id,
                meta,
                assembly
            ]
        }
        .join(
            BGZIP_HIFI.out.output
                .filter {
                    meta, _assembly -> meta.strategy == "scaffold" &&
                        meta.assembler_ont == "hifiasm" &&
                        meta.assembler_hifi == "hifiasm"
                }
                .map {
                    meta, assembly ->
                    [
                        meta.id,
                        assembly
                    ]
                }
        )
        .map {
            _id, meta, assembly_ont, assembly_hifi ->
            [
                meta: meta +
                    [
                        assembly_ont: assembly_ont,
                        assembly_hifi: assembly_hifi
                    ]
            ]
        }

    // branch to scaffold those assemblies that need it

    ch_to_scaffold = scaffold_flye_hifiasm
        .mix(scaffold_flye_flye)
        .mix(scaffold_hifiasm_flye)
        .mix(scaffold_hifiasm_hifiasm)

    ch_to_scaffold.dump(tag: "Assemble: Assemblies with scaffolding - inputs")

    // For scaffolding, depeding on which strategy used, the correct assembly needs to go into either target or query:
    // assembly_ont is always ONT, assembly_hifi is always HiFi

    ragtag_in = ch_to_scaffold
        .multiMap {
            it ->
            target: [
                it.meta,
                it.meta.assembly_scaffolding_order == "ont_on_hifi" ? (it.meta.assembly_ont) : (it.meta.assembly_hifi)
                ]
            query: [
                it.meta,
                it.meta.assembly_scaffolding_order == "ont_on_hifi" ? (it.meta.assembly_hifi) : (it.meta.assembly_ont)
                ]
        }

    ragtag_in.target.dump(tag: "ASSEMBLE: SCAFFOLD: RAGTAG_PATCH INPUT: TARGET")
    ragtag_in.query.dump( tag: "ASSEMBLE: SCAFFOLD: RAGTAG_PATCH INPUT: QUERY")
    // Scaffold with PATCH
    RAGTAG_PATCH(ragtag_in.target, ragtag_in.query, [[], []], [[], []] )
    ch_to_zip_ragtag = RAGTAG_PATCH.out.patch_fasta.map {
        meta, polished ->
        [
            meta,
            polished,
            [],
            []
        ]
    }

    BGZIP_RAGTAG(ch_to_zip_ragtag, "compress", false, "fa")
    // Update meta
    ch_assemblies_scaffold = BGZIP_RAGTAG.out.output
        .map { meta, patched -> [meta: meta + [assembly: patched] ] }

    ch_assemblies_scaffold.dump(tag: "Assemble: Assemblies with scaffolding - outputs")

    // Mix everything assembled back togehter
    ch_main_assembled = ch_assemblies_no_scaffold
        .mix(ch_assemblies_scaffold)

    ch_main_assembled.dump(tag: "Assemble: Assembled")

    // Mix with whatever was not destined for assembly
    ch_main_to_mapping = ch_main_branched
        .no_assemble
        .mix( ch_main_assembled )

    ch_main_to_mapping.dump(tag: "Assemble: TO MAPPING")

    // QUAST is the only QC tool that requires mapping
    // Note that this channel is set here but only the quast branch is further used
    ch_main_quast_branch = ch_main_to_mapping
        .branch {
            it ->
            quast: it.meta.quast
            no_quast: !it.meta.quast
        }


    // If QUAST should run, and we need an alignment to reference, this is created here
    ch_quast_branched = ch_main_quast_branch
        .quast
        .branch {
            it ->
                use_ref: it.meta.use_ref
                no_use_ref: !it.meta.use_ref
        }

    // Alignment is actually only created if no bam file is provided
    ch_ref_mapping_branched = ch_quast_branched
        .use_ref
        .branch { it ->
            to_map: !it.meta.ref_map_bam
            dont_map: it.meta.ref_map_bam
        }

    // Use the QC reads and map them to ref
    map_to_ref_in = ch_ref_mapping_branched
        .to_map
        .map {
            it ->
            [ it.meta, it.meta.qc_reads_path, it.meta.ref_fasta ]
        }

    MAP_TO_REF(map_to_ref_in)

    // Add the ref mapping to the large main channel
    ch_main_to_qc = MAP_TO_REF.out.ch_aln_to_ref_bam
        .map { meta, bam -> [ meta: meta + [ref_map_bam: bam] ] }
        .mix(ch_ref_mapping_branched.dont_map)
        .mix(ch_quast_branched.no_use_ref)
        // above recreates ch_main_quast_branch.quast
        .mix(ch_main_quast_branch.no_quast)

    ch_main_to_qc.dump(tag: "ASSEMBLE: QC INPUT")
    //QC on initial assembly

    // scaffolds to QC need to be defined here, this is what is in the assembly slot
    scaffolds = ch_main_to_qc
        .map { it -> [it.meta.id, it.meta.assembly] }

    QC(ch_main_to_qc, scaffolds, meryl_kmers)

    // If annotation liftover on the initial assembly is desired, it happens here.
    liftoff_in = ch_main_to_qc
        .filter {
            it -> it.meta.lift_annotations
        }
        .map { it ->
            [
                it.meta,
                it.meta.assembly,
                it.meta.ref_fasta,
                it.meta.ref_gff
            ]
        }

    liftoff_in.dump(tag: "ASSEMBLE: LIFTOFF: INPUT")
    LIFTOFF(liftoff_in, [])

    emit:
    ch_main                     = ch_main_to_qc
    assembly_quast_reports      = QC.out.quast_out
    assembly_busco_reports      = QC.out.busco_out
    assembly_merqury_reports    = QC.out.merqury_report_files
}
