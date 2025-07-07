/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
include { paramsSummaryMap } from 'plugin/nf-schema'
include { paramsSummaryMultiqc } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { softwareVersionsToYAML } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { methodsDescriptionText } from '../subworkflows/local/utils_nfcore_genomeassembler_pipeline'
// Read preparation
include { PREPARE_ONT } from '../subworkflows/local/prepare_ont/main'
include { PREPARE_HIFI } from '../subworkflows/local/prepare_hifi/main'
include { PREPARE_SHORTREADS } from '../subworkflows/local/prepare_shortreads/main'

// Read checks
include { ONT } from '../subworkflows/local/ont/main'
include { HIFI } from '../subworkflows/local/hifi/main'

// Assembly
include { ASSEMBLE } from '../subworkflows/local/assemble/main'

// Polishing
include { POLISH } from '../subworkflows/local/polishing/main'

// Scaffolding
include { SCAFFOLD } from '../subworkflows/local/scaffolding/main'
// reporting
include { REPORT } from '../modules/local/report/main'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow GENOMEASSEMBLER {
    take:
    ch_input

    main:
    // Initialize empty channels
    ch_input.set { ch_main }

    /*
    This is the "main" channel, it contains all sample-wise information.
    This channel should be the main input of all subworkflows,
    and the subworkflows should make relevant changes / updates to the map.
    This channel should stay a map (!!) to allow key-based modifications in subworkflows.
    The keys are defined in subworkflows/local/utils_nfcore_genomeassembler/main.nf
    Here is a list of keys and their types that come in :

        meta: [id: string],
        ontreads: path,
        hifireads: path,
        strategy: string,
        assembler1: string,
        assembler2: string,
        scaffolding: string,
        genome_size: integer,
        assembler1_args: string,
        assembler2_args: string,
        ref_fasta: path,
        ref_gff: path,
        shortread_F: path,
        shortread_R: path,
        paired: bool
        ont_collect: bool,
        ont_trim: bool,
        ont_jellyfish: bool,
        hifi_trim: bool,
        hifi_primers: path,
        polish_medaka: bool,
        medaka_model: string,
        polish_pilon: bool,
        scaffold_longstitch: bool,
        scaffold_links: bool,
        scaffold_ragtag: bool,
        use_ref: bool,
        flye_mode: string,
        // assembly already provided?
        assembly: path,
        // ref mapping provided?
        ref_map_bam: path,
        // assembly mapping provided
        assembly_map_bam: path,
        // reads for qc
        qc_reads: string ["ont","hifi"],
        qc_reads_path: path,
        quast: bool,
        busco: bool,
        busco_lineage: string,
        busco_db: path,
        lift_annotations: bool,
        // short read options
        shortread_F: path,
        shortread_R: path,
        paired: bool,
        use_short_reads: bool,
        shortread_trim: bool
    */

    Channel.empty().set { meryl_kmers }

    Channel.empty().set { ch_versions }

    // Initialize channels for QC report collection
    Channel
        .of([])
        .tap { quast_files }
        .tap { nanoq_files }
        .tap { genomescope_files }
        .map { it -> ["dummy", it] }
        .tap { busco_files }
        .map { it -> [it[0], it[1], it[1], it[1], it[1]] }
        .tap { merqury_files }
    /*
    =============
    Prepare reads
    =============
    */
    /*
    Short reads
    */
    ch_main
        .filter {
            it -> it.shortread_F ? true : false
        }
        .set { shortreads }

    shortreads.view(it -> "SHORTREADS: $it")
    // adapted to sample-logic
    PREPARE_SHORTREADS(shortreads)
    // This changes ch_main shortreads_F and _R become one tuple, paired is gone.

    // put shortreads back together with samples without shortreads
    ch_main
        .filter {
            it -> !it.shortread_F ? true : false
        }
        .map { it -> it - it.subMap["shortread_F","shortread_R", "paired"] + [shorteads: null] }
        .mix(PREPARE_SHORTREADS.out.shortreads)
        .set { ch_main_shortreaded }

    PREPARE_SHORTREADS.out.meryl_kmers.set { meryl_kmers }

    ch_versions = ch_versions.mix(PREPARE_SHORTREADS.out.versions)

    /*
    ONT reads
    */

    // adapted to sample-logic
    ONT(ch_main_shortreaded)

    ONT.out.main_out.set { ch_main_onted }

    ONT.out.nanoq_report
        .concat(
            ONT.out.nanoq_stats
        )
        .collect { it -> it[1] }
        .set { nanoq_files }

    ONT.out.genomescope_summary
        .concat(
            ONT.out.genomescope_plot
        )
        .unique()
        .collect { it -> it[1] }
        .set { genomescope_files }

    ch_versions = ch_versions.mix(ONT.out.versions)


    /*
    HIFI reads
    */

    // adapted to sample-logic

    HIFI(ch_main_onted)

    HIFI.out.main_out.set { ch_main_prepared }

    ch_versions = ch_versions.mix(HIFI.out.versions)
    /*
    Assembly
    */
    // This pipeline is named genomeassembler, so everything goes into assemble
    // even it might not actually be assembled.
    ASSEMBLE(ch_main_prepared, meryl_kmers)

    ASSEMBLE.out.ch_main.set { ch_main_assembled }

    ch_versions = ch_versions.mix(ASSEMBLE.out.versions)
    /*
    Polishing
    */
    ch_main_assembled
        .branch {
            it ->
            polish: it.polish_medaka || it.polish_pilon
            no_polish: !it.polish_medaka && !it.polish_pilon
        }
        .set { ch_main_assembled }

    POLISH(ch_main_assembled.polish, meryl_kmers)

    ch_main_assembled.no_polish
        .mix(POLISH.out.ch_main)
        .set { ch_main_polished }

    ch_versions = ch_versions.mix(POLISH.out.versions)

    ch_main_polished
        .branch {
            scaffold: it.scaffold_links || it.scaffold_longstitch || it.scaffold_ragtag
            no_scaffold: !it.scaffold_links && !it.scaffold_longstitch && !it.scaffold_ragtag
        }
    .set {
        ch_main_polished
    }
    /*
    Scaffolding
    */
    SCAFFOLD(ch_main_polished.scaffold, meryl_kmers)

    // Recreate ch_main, even though it is not used since there are no later steps._report

    ch_main_polished
        .no_scaffold
        .mix(SCAFFOLD.out.ch_main)
        .set { ch_main_scaffolded }


    ch_versions = ch_versions.mix(SCAFFOLD.out.versions)

    /*
    Report
    */
    softwareVersionsToYAML(ch_versions)
        .collectFile(
            storeDir: "${params.outdir}/pipeline_info",
            name: 'nf_core_' + 'pipeline_software_' + 'versions.yml',
            sort: true,
            newLine: true
        )

    quast_files
        .concat(
            ASSEMBLE.out.assembly_quast_reports.concat(
                POLISH.out.polish_quast_reports
            ).concat(
                SCAFFOLD.out.scaffold_quast_reports
            )
        )
        .unique()
        .collect()
        .set { quast_files }

    busco_files
        .concat(
            ASSEMBLE.out.assembly_busco_reports.concat(
                POLISH.out.polish_busco_reports
            ).concat(
                SCAFFOLD.out.scaffold_busco_reports
            )
        )
        .unique()
        .collect { it -> it[1] }
        .set { busco_files }

    merqury_files
        .concat(
            ASSEMBLE.out.assembly_merqury_reports.concat(
                POLISH.out.polish_merqury_reports
            ).concat(
                SCAFFOLD.out.scaffold_merqury_reports
            )
        )
        .collect { it -> [it[1], it[2], it[3], it[4]] }
        .toSet()
        .flatten()
        .collect()
        .set { merqury_files }

    Channel
        .fromPath("${projectDir}/assets/report/*")
        .collect()
        .set { report_files }
    // Report files
    Channel
        .fromPath("${projectDir}/assets/report/functions/*")
        .collect()
        .set { report_functions }

    if(!params.merqury) {
        merqury_files = Channel.of([])
    }

    REPORT(report_files, report_functions, nanoq_files, genomescope_files, quast_files, busco_files, merqury_files, Channel.fromPath("${params.outdir}/pipeline_info/nf_core_pipeline_software_versions.yml"))

    //
    // Collate and save software versions
    //
    softwareVersionsToYAML(ch_versions)
        .collectFile(
            storeDir: "${params.outdir}/pipeline_info",
            name: 'nf_core_'  +  'genomeassembler_software_'  + 'versions.yml',
            sort: true,
            newLine: true
        )

    _report = REPORT.out.report_html.toList()

    emit:
    _report
    versions = ch_versions // channel: [ path(versions.yml) ]
}
