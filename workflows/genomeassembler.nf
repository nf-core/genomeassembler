/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    VALIDATE INPUTS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

def summary_params = NfcoreSchema.paramsSummaryMap(workflow, params)

// Validate input parameters
// WorkflowGenomeassembler.initialise(params, log)

// TODO nf-core: Add all file path parameters for the pipeline to the list below
// Check input path parameters to see if they exist
def checkPathParamList = [ params.input, params.multiqc_config ]
for (param in checkPathParamList) { if (param) { file(param, checkIfExists: true) } }

// Check mandatory parameters
ch_input = Channel.fromPath( params.input, checkIfExists: true )
    .ifEmpty { exit 1, 'Error: Input samplesheet not specified!' }
// if (params.input) { ch_input = file(params.input) } else { exit 1, 'Input samplesheet not specified!' }

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    CONFIG FILES
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

ch_multiqc_config          = Channel.fromPath("$projectDir/assets/multiqc_config.yml", checkIfExists: true)
ch_multiqc_custom_config   = params.multiqc_config ? Channel.fromPath( params.multiqc_config, checkIfExists: true ) : Channel.empty()
ch_multiqc_logo            = params.multiqc_logo   ? Channel.fromPath( params.multiqc_logo, checkIfExists: true ) : Channel.empty()
ch_multiqc_custom_methods_description = params.multiqc_methods_description ? file(params.multiqc_methods_description, checkIfExists: true) : file("$projectDir/assets/methods_description_template.yml", checkIfExists: true)

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT LOCAL MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// SUBWORKFLOW: Consisting of a mix of local and nf-core/modules
//
// include { INPUT_CHECK } from '../subworkflows/local/input_check'
include { PREPARE_INPUT } from "$projectDir/subworkflows/local/prepare_input"

include { BUILD_KMER_DATABASES as BUILD_HIFI_KMER_DATABASE     } from "$projectDir/subworkflows/local/build_kmer_databases"
include { BUILD_KMER_DATABASES as BUILD_HIC_KMER_DATABASE      } from "$projectDir/subworkflows/local/build_kmer_databases"
include { BUILD_KMER_DATABASES as BUILD_ONT_KMER_DATABASE      } from "$projectDir/subworkflows/local/build_kmer_databases"
include { BUILD_KMER_DATABASES as BUILD_ILLUMINA_KMER_DATABASE } from "$projectDir/subworkflows/local/build_kmer_databases"

include { DATA_PROPERTIES as HIFI_DATA_PROPERTIES     } from "$projectDir/subworkflows/local/data_properties"
include { DATA_PROPERTIES as HIC_DATA_PROPERTIES      } from "$projectDir/subworkflows/local/data_properties"
include { DATA_PROPERTIES as ONT_DATA_PROPERTIES      } from "$projectDir/subworkflows/local/data_properties"
include { DATA_PROPERTIES as ILLUMINA_DATA_PROPERTIES } from "$projectDir/subworkflows/local/data_properties"

include { GENOME_PROPERTIES as HIFI_GENOME_PROPERTIES     } from "$projectDir/subworkflows/local/genome_properties"
include { GENOME_PROPERTIES as HIC_GENOME_PROPERTIES      } from "$projectDir/subworkflows/local/genome_properties"
include { GENOME_PROPERTIES as ONT_GENOME_PROPERTIES      } from "$projectDir/subworkflows/local/genome_properties"
include { GENOME_PROPERTIES as ILLUMINA_GENOME_PROPERTIES } from "$projectDir/subworkflows/local/genome_properties"

include { CONTAMINATION_SCREEN as HIFI_CONTAMINATION_SCREEN     } from "$projectDir/subworkflows/local/contamination_screen"
include { CONTAMINATION_SCREEN as HIC_CONTAMINATION_SCREEN      } from "$projectDir/subworkflows/local/contamination_screen"
include { CONTAMINATION_SCREEN as ONT_CONTAMINATION_SCREEN      } from "$projectDir/subworkflows/local/contamination_screen"
include { CONTAMINATION_SCREEN as ILLUMINA_CONTAMINATION_SCREEN } from "$projectDir/subworkflows/local/contamination_screen"

// include { ASSEMBLY_EVALUATION } from "$projectDir/subworkflows/local/assembly_evaluation"
include { ASSEMBLY_COMPARISON } from "$projectDir/subworkflows/local/assembly_comparison"

include { EVALUATE_KMER_COMPLETENESS as EVALUATE_HIFI_KMER_COMPLETENESS     } from "$projectDir/subworkflows/local/evaluate_kmer_completeness"
include { EVALUATE_KMER_COMPLETENESS as EVALUATE_HIC_KMER_COMPLETENESS      } from "$projectDir/subworkflows/local/evaluate_kmer_completeness"
include { EVALUATE_KMER_COMPLETENESS as EVALUATE_ONT_KMER_COMPLETENESS      } from "$projectDir/subworkflows/local/evaluate_kmer_completeness"
include { EVALUATE_KMER_COMPLETENESS as EVALUATE_ILLUMINA_KMER_COMPLETENESS } from "$projectDir/subworkflows/local/evaluate_kmer_completeness"

include { EVALUATE_GENE_SPACE } from "$projectDir/subworkflows/local/evaluate_gene_space"
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT NF-CORE MODULES/SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// MODULE: Installed directly from nf-core/modules
//
// include { FASTQC                      } from '../modules/nf-core/modules/fastqc/main'
// include { MULTIQC                     } from '../modules/nf-core/modules/multiqc/main'
include { CUSTOM_DUMPSOFTWAREVERSIONS } from "$projectDir/modules/nf-core/custom/dumpsoftwareversions/main"

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

// Info required for completion email and summary
def multiqc_report = []

workflow GENOMEASSEMBLER {

    ch_versions = Channel.empty()

    //
    // SUBWORKFLOW: Read in samplesheet, validate and stage input files
    //
    // INPUT_CHECK (
    //     ch_input
    // )
    PREPARE_INPUT (
        ch_input
    )
    // ch_versions = ch_versions.mix(PREPARE_INPUT.out.versions)

    // BUILD KMER DATABASES
    BUILD_HIFI_KMER_DATABASE( PREPARE_INPUT.out.hifi )
    BUILD_HIC_KMER_DATABASE( PREPARE_INPUT.out.hic)
    BUILD_ONT_KMER_DATABASE( PREPARE_INPUT.out.ont )
    BUILD_ILLUMINA_KMER_DATABASE( PREPARE_INPUT.out.illumina )

    // DATA QUALITY CHECKS:
    // - Check data properties
    HIFI_DATA_PROPERTIES(
        PREPARE_INPUT.out.hifi,
        false // short read data
    )
    HIC_DATA_PROPERTIES(
        PREPARE_INPUT.out.hic,
        true // short read data
    )
    ONT_DATA_PROPERTIES(
        PREPARE_INPUT.out.ont,
        false // short read data
    )
    ILLUMINA_DATA_PROPERTIES(
        PREPARE_INPUT.out.illumina,
        true // short read data
    )
    // - Check genome properties
    HIFI_GENOME_PROPERTIES(
        BUILD_HIFI_KMER_DATABASE.out.fastk_histogram.join( BUILD_HIFI_KMER_DATABASE.out.fastk_ktab ),
        BUILD_HIFI_KMER_DATABASE.out.meryl_histogram
    )
    HIC_GENOME_PROPERTIES(
        BUILD_HIC_KMER_DATABASE.out.fastk_histogram.join( BUILD_HIC_KMER_DATABASE.out.fastk_ktab ),
        BUILD_HIC_KMER_DATABASE.out.meryl_histogram
    )
    ONT_GENOME_PROPERTIES(
        BUILD_ONT_KMER_DATABASE.out.fastk_histogram.join( BUILD_ONT_KMER_DATABASE.out.fastk_ktab ),
        BUILD_ONT_KMER_DATABASE.out.meryl_histogram
    )
    ILLUMINA_GENOME_PROPERTIES(
        BUILD_ILLUMINA_KMER_DATABASE.out.fastk_histogram.join( BUILD_ILLUMINA_KMER_DATABASE.out.fastk_ktab ),
        BUILD_ILLUMINA_KMER_DATABASE.out.meryl_histogram
    )
    // - Screen for contaminants
    mash_db_ch = Channel.fromPath( params.mash_screen_db, checkIfExists: true ).collect()
    HIFI_CONTAMINATION_SCREEN(
        PREPARE_INPUT.out.hifi,
        mash_db_ch
    )
    HIC_CONTAMINATION_SCREEN(
        PREPARE_INPUT.out.hic,
        mash_db_ch
    )
    ONT_CONTAMINATION_SCREEN(
        PREPARE_INPUT.out.ont,
        mash_db_ch
    )
    ILLUMINA_CONTAMINATION_SCREEN(
        PREPARE_INPUT.out.illumina,
        mash_db_ch
    )
    // - Compare library content


    // PREPROCESSING:
    // - adapter trimming
    // - contaminant filtering
    // - downsampling
    // - normalisation

    // ASSEMBLY:
    // - assemble
    // - scaffold
    // - polish

    // ASSEMBLY EVALUATION:
    // - Compare assemblies
    reference_ch = params.reference ? Channel.fromPath( params.reference, checkIfExists: true ).collect() : Channel.value([])
    ASSEMBLY_COMPARISON(
        PREPARE_INPUT.out.assemblies.mix(
            Channel.empty() // Replace with workflow assembled genomes
        ),
        reference_ch
    )
    // - Check K-mer completeness
    EVALUATE_HIFI_KMER_COMPLETENESS(
        PREPARE_INPUT.out.assemblies,
        BUILD_HIFI_KMER_DATABASE.out.fastk_histogram.join( BUILD_HIFI_KMER_DATABASE.out.fastk_ktab )
    )
    EVALUATE_HIC_KMER_COMPLETENESS(
        PREPARE_INPUT.out.assemblies,
        BUILD_HIC_KMER_DATABASE.out.fastk_histogram.join( BUILD_HIC_KMER_DATABASE.out.fastk_ktab )
    )
    EVALUATE_ONT_KMER_COMPLETENESS(
        PREPARE_INPUT.out.assemblies,
        BUILD_ONT_KMER_DATABASE.out.fastk_histogram.join( BUILD_ONT_KMER_DATABASE.out.fastk_ktab )
    )
    EVALUATE_ILLUMINA_KMER_COMPLETENESS(
        PREPARE_INPUT.out.assemblies,
        BUILD_ILLUMINA_KMER_DATABASE.out.fastk_histogram.join( BUILD_ILLUMINA_KMER_DATABASE.out.fastk_ktab )
    )
    // - Check gene space
    EVALUATE_GENE_SPACE(
        PREPARE_INPUT.out.assemblies,
        params.busco_lineages instanceof List ? params.busco_lineages : params.busco_lineages.tokenize(','),
        params.busco_lineage_path ? file( params.busco_lineage_path, checkIfExists: true ) : []
    )
    // - Check contamination
    // - Visualize assembly graph
    // - Generate annotation tracks
    // ASSEMBLY_EVALUATION( // TODO: Separate this
    //     PREPARE_INPUT.out.assemblies,
    //     PREPARE_INPUT.out.hifi,
    //     PREPARE_INPUT.out.hic,
    //     PREPARE_INPUT.out.ont,
    //     PREPARE_INPUT.out.illumina,
    //     BUILD_HIFI_KMER_DATABASE.out.fastk_histogram.join( BUILD_HIFI_KMER_DATABASE.out.fastk_ktab ),
    //     BUILD_HIC_KMER_DATABASE.out.fastk_histogram.join( BUILD_HIC_KMER_DATABASE.out.fastk_ktab ),
    //     BUILD_ONT_KMER_DATABASE.out.fastk_histogram.join( BUILD_ONT_KMER_DATABASE.out.fastk_ktab ),
    //     BUILD_ILLUMINA_KMER_DATABASE.out.fastk_histogram.join( BUILD_ILLUMINA_KMER_DATABASE.out.fastk_ktab ),
    //     reference_ch,
    //     params.busco_lineages instanceof List ? params.busco_lineages : params.busco_lineages.tokenize(','),
    //     params.busco_lineage_path ? file( params.busco_lineage_path, checkIfExists: true ) : []
    // )

    // ASSEMBLY CURATION:
    // - Purge duplications
    // - Fix misassemblies
    // - Separate organelles, plasmids, etc
    // - recircularize circular genomes
    // - evaluate assemblies

    CUSTOM_DUMPSOFTWAREVERSIONS (
        ch_versions.unique().collectFile(name: 'collated_versions.yml')
    )

    //
    // MODULE: MultiQC
    //
    // workflow_summary    = WorkflowGenomeassembler.paramsSummaryMultiqc(workflow, summary_params)
    // ch_workflow_summary = Channel.value(workflow_summary)

    methods_description    = WorkflowGenomeassembler.methodsDescriptionText(workflow, ch_multiqc_custom_methods_description)
    ch_methods_description = Channel.value(methods_description)

    // ch_multiqc_files = Channel.empty()
    // ch_multiqc_files = ch_multiqc_files.mix(ch_workflow_summary.collectFile(name: 'workflow_summary_mqc.yaml'))
    // ch_multiqc_files = ch_multiqc_files.mix(ch_methods_description.collectFile(name: 'methods_description_mqc.yaml'))
    // ch_multiqc_files = ch_multiqc_files.mix(CUSTOM_DUMPSOFTWAREVERSIONS.out.mqc_yml.collect())
    // ch_multiqc_files = ch_multiqc_files.mix(FASTQC.out.zip.collect{it[1]}.ifEmpty([]))

    // MULTIQC (
    //     ch_multiqc_files.collect(),
    //     ch_multiqc_config.collect().ifEmpty([]),
    //     ch_multiqc_custom_config.collect().ifEmpty([]),
    //     ch_multiqc_logo.collect().ifEmpty([])
    // )
    // multiqc_report = MULTIQC.out.report.toList()
    // ch_versions    = ch_versions.mix(MULTIQC.out.versions)
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    COMPLETION EMAIL AND SUMMARY
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow.onComplete {
    if (params.email || params.email_on_fail) {
        NfcoreTemplate.email(workflow, params, summary_params, projectDir, log, multiqc_report)
    }
    NfcoreTemplate.summary(workflow, params, log)
    if (params.hook_url) {
        NfcoreTemplate.adaptivecard(workflow, params, summary_params, projectDir, log)
    }
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
