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
    ch_refs

    main:
    // Initialize empty channels
    ch_input.set { ch_main }
    /*
    This is the "main" channel, it contains all sample-wise information.
    This channel should be the main input of all subworkflows,
    and the subworkflows should make relevant changes / updates to the map.
    This channel should stay a map to allow key-based modifications in subworkflows.
    The keys are defined in subworkflows/local/utils_nfcore_genomeassembler/main.nf :

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

    */
    Channel.empty().set { ch_ref_bam }
    Channel.empty().set { ch_polished_genome }
    Channel.empty().set { ch_shortreads }
    Channel.empty().set { meryl_kmers }
    Channel.empty().set { genome_size }
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
    if (params.short_reads) {
        PREPARE_SHORTREADS(ch_main)
        PREPARE_SHORTREADS.out.main_out.set { ch_main }
        // This changes ch_main shortreads_F and _R become one tuple, paired is gone.
        PREPARE_SHORTREADS.out.meryl_kmers.set { meryl_kmers }
        ch_versions = ch_versions.mix(PREPARE_SHORTREADS.out.versions)
    }

    /*
    ONT reads
    */
    if (params.ont) {
        ONT(ch_main)

        ONT.out.main_out.set { ch_main }

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
    }


    /*
    HIFI reads
    */
    if (params.hifi) {
        HIFI(ch_main)
        HIFI.out.main_out.set { ch_main }

        ch_versions = ch_versions.mix(HIFI.out.versions)
    }

    /*
    Assembly
    */

    ASSEMBLE( ch_main, meryl_kmers)
    ASSEMBLE.out.assembly.set { ch_polished_genome }
    ASSEMBLE.out.ref_bam.set { ch_ref_bam }
    ASSEMBLE.out.longreads.set { ch_longreads }
    ch_versions = ch_versions.mix(ASSEMBLE.out.versions)
    /*
    Polishing
    */

    POLISH(ch_input, ch_ont_reads, ch_longreads, ch_shortreads, ch_polished_genome, ch_ref_bam, meryl_kmers)
    POLISH.out.ch_polished_genome.set { ch_polished_genome }

    ch_versions = ch_versions.mix(POLISH.out.versions)

    /*
    Scaffolding
    */
    SCAFFOLD(ch_input, ch_longreads, ch_polished_genome, ch_refs, ch_ref_bam, meryl_kmers, genome_size)

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
