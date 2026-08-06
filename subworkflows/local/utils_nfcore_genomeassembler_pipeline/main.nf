//
// Subworkflow with functionality specific to the nf-core/genomeassembler pipeline
//

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT FUNCTIONS / MODULES / SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { UTILS_NFSCHEMA_PLUGIN     } from '../../nf-core/utils_nfschema_plugin'
include { paramsSummaryMap          } from 'plugin/nf-schema'
include { samplesheetToList         } from 'plugin/nf-schema'
include { paramsHelp                } from 'plugin/nf-schema'
include { completionEmail           } from '../../nf-core/utils_nfcore_pipeline'
include { completionSummary         } from '../../nf-core/utils_nfcore_pipeline'
include { UTILS_NFCORE_PIPELINE     } from '../../nf-core/utils_nfcore_pipeline'
include { UTILS_NEXTFLOW_PIPELINE   } from '../../nf-core/utils_nextflow_pipeline'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    SUBWORKFLOW TO INITIALISE PIPELINE
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow PIPELINE_INITIALISATION {
    take:
    version // boolean: Display version and exit
    validate_params // boolean: Boolean whether to validate parameters against the schema at runtime
    monochrome_logs // boolean: Do not use coloured log outputs
    nextflow_cli_args //   array: List of positional nextflow CLI args
    outdir            //  string: The output directory where the results will be saved
    input             //  string: Path to input samplesheet
    help              // boolean: Display help message and exit
    help_full         // boolean: Show the full help message
    show_hidden       // boolean: Show hidden parameters in the help message

    main:

    ch_versions = channel.empty()

    //
    // Print version and exit if required and dump pipeline parameters to JSON file
    //
    UTILS_NEXTFLOW_PIPELINE(
        version,
        true,
        outdir,
        workflow.profile.tokenize(',').intersect(['conda', 'mamba']).size() >= 1,
    )

    //
    // Validate parameters and generate parameter summary to stdout
    //

    def before_text = ""
    def after_text = ""
    before_text = """
-\033[2m----------------------------------------------------\033[0m-
                                        \033[0;32m,--.\033[0;30m/\033[0;32m,-.\033[0m
\033[0;34m        ___     __   __   __   ___     \033[0;32m/,-._.--~\'\033[0m
\033[0;34m  |\\ | |__  __ /  ` /  \\ |__) |__         \033[0;33m}  {\033[0m
\033[0;34m  | \\| |       \\__, \\__/ |  \\ |___     \033[0;32m\\`-._,-`-,\033[0m
                                        \033[0;32m`._,._,\'\033[0m
\033[0;35m  nf-core/genomeassembler ${workflow.manifest.version}\033[0m
-\033[2m----------------------------------------------------\033[0m-
"""
    after_text = """${workflow.manifest.doi ? "\n* The pipeline\n" : ""}${workflow.manifest.doi.tokenize(",").collect { doi -> "    https://doi.org/${doi.trim().replace('https://doi.org/','')}"}.join("\n")}${workflow.manifest.doi ? "\n" : ""}
* The nf-core framework
    https://doi.org/10.1038/s41587-020-0439-x

* Software dependencies
    https://github.com/nf-core/genomeassembler/blob/master/CITATIONS.md
"""
    if (monochrome_logs) {
        before_text = before_text.replaceAll(/\033\[[0-9;]*m/, '')
    }

    command = "nextflow run ${workflow.manifest.name} -profile <docker/singularity/.../institute> --input samplesheet.csv --outdir <OUTDIR>"

    UTILS_NFSCHEMA_PLUGIN (
        workflow,
        validate_params,
        null,
        help,
        help_full,
        show_hidden,
        before_text,
        after_text,
        command
    )

    //
    // Check config provided to the pipeline
    //
    UTILS_NFCORE_PIPELINE(
        nextflow_cli_args
    )

    //
    // Create channel from input file provided through params.input
    //

    ch_samplesheet = channel.fromPath(params.input)
        .splitCsv(header: true)
        /*
        This is a somewhat crucial step, where the samplesheet and params are used to determine per-sample parameters.
        */
        .map { it ->
            def strategy        =   it.strategy ?: params.strategy
            def ontreads        =   it.ontreads ?: params.ontreads
            def hifireads       =   it.hifireads ?: params.hifireads
            def assembler       =   it.assembler ?: params.assembler
            def assembler_ont   =   it.assembler_ont ?:
                                    (strategy == "single" && assembler && ontreads && !hifireads) ? assembler :
                                    params.assembler_ont ?:
                                    (strategy == "hybrid" && assembler == "hifiasm") ? assembler :
                                    assembler.contains("_") ? assembler.tokenize("_")[0] :
                                    null
            def assembler_hifi  =   it.assembler_hifi ?:
                                    (strategy == "single" && assembler && hifireads && !ontreads) ? assembler :
                                    params.assembler_hifi ?:
                                    assembler.contains("_") ? assembler.tokenize("_")[1] :
                                    null
            def polish          =   it.polish ?:
                                    (params.polish_medaka && params.polish_dorado) ? error("Both polish_medaka and polish_dorado are set.") :
                                    (params.polish_medaka && params.polish_pilon && ontreads) ? "medaka+pilon" :
                                    (params.polish_dorado && params.polish_pilon && ontreads) ? "dorado+pilon" :
                                    (params.polish_medaka && ontreads) ? "medaka" :
                                    (params.polish_dorado && ontreads) ? "dorado" :
                                    (params.polish_pilon && (it.shortread_F || params.shortread_F)) ? "pilon" :
                                    null
            def hic_F           =   it.hic_F ?: params.hic_F
            def scaffold_hic    =   hic_F ? (it.scaffold_hic != null ? it.scaffold_hic : params.scaffold_hic) : false
            def hic_trim        =   !scaffold_hic ? false :
                                    (it.hic_trim ?: params.hic_trim)
            def assembler_ont_args =  it.assembler_ont_args ?: params.assembler_ont_args ?: ''
            def assembler_hifi_args = it.assembler_hifi_args ?: params.assembler_hifi_args ?: ''
            // Check if strategy can be inferred
            strategy == "single" && ontreads && hifireads && !((!assembler_ont && assembler_hifi) || (assembler_ont && !assembler_hifi)) ?
                error(
                    """
                    [$it.sample]: Strategy is 'single', but ONT and HiFi reads are provided.
                    Please unambigiously define either 'assembler_ont' for ONT or 'assembler_hifi' for HiFi
                    """
                ) :
                null
            // Build the map. Everything goes into meta.
            [
                meta: [
                    id: it.sample,
                    // new in refactor-assemblies
                    group: it.group ?: null,
                    ontreads: ontreads,
                    hifireads: hifireads,
                    // new in refactor-assemblers
                    strategy: strategy,
                    // The "assembler" value is mainly to ease input, all actual workflow logic should use assembler_ont/_hifi.
                    assembler: assembler,
                    assembler_ont: assembler_ont,
                    assembler_hifi: assembler_hifi,
                    assembly_scaffolding_order: it.assembly_scaffolding_order ?: params.assembly_scaffolding_order ?: "ont_on_hifi",
                    assembler_ont_args: assembler_ont_args,
                    assembler_hifi_args: assembler_hifi_args,
                    hifiasm_args: it.hifiasm_args ?: params.hifiasm_args,
                    flye_args: it.flye_args ?: params.flye_args,
                    polish: polish,
                    ont_collect: it.ont_collect ?: params.ont_collect,
                    ont_adapters: it.ont_adapters ?: params.ont_adapters,
                    ont_fastplong_args: it.ont_fastplong_args ?: params.ont_fastplong_args,
                    jellyfish: it.jellyfish ?: params.jellyfish,
                    jellyfish_k: it.ont_jellyfish_k ?: params.jellyfish_k,
                    jellyfish_size: it.jellyfish_size ?: params.jellyfish_size,
                    hifi_adapters: it.hifi_adapters ?: params.hifi_adapters,
                    hifi_fastplong_args: it.hifi_fastplong_args ?: params.hifi_fastplong_args,
                    medaka_model: it.medaka_model ?: params.medaka_model,
                    scaffold_longstitch: it.scaffold_longstitch ?: params.scaffold_longstitch,
                    scaffold_links: it.scaffold_links ?: params.scaffold_links,
                    scaffold_ragtag: it.scaffold_ragtag ?: params.scaffold_ragtag,
                    scaffold_hic: scaffold_hic,
                    use_ref: it.use_ref ?: params.use_ref,
                    // hic
                    hic_aligner: it.hic_aligner ?: params.hic_aligner,
                    hic_F: scaffold_hic ? (hic_F) : [],
                    hic_R: scaffold_hic ? (it.hic_R ?: params.hic_R) : [],
                    hic_trim: hic_trim,
                    // not new
                    genome_size: it.genome_size ?: params.genome_size,
                    ref_fasta: it.ref_fasta ?: params.ref_fasta,
                    ref_gff: it.ref_gff ?: params.ref_gff,
                    flye_mode: it.flye_mode ?: params.flye_mode,
                    // assembly already provided?
                    assembly: it.assembly ?: params.assembly ?: null,
                    // ref mapping provided?
                    ref_map_bam: it.ref_map_bam ?: params.ref_map_bam ?: null,
                    // assembly mapping provided
                    assembly_map_bam: it.assembly_map_bam ?: params.ref_map_bam ?: null,
                    // reads for qc
                    qc_reads: ((it.qc_reads == "ont" || params.qc_reads == "ont") && ontreads) ? "ont" : "hifi",
                    qc_reads_path: ((it.qc_reads == "ont" || params.qc_reads == "ont") && ontreads) ? ontreads : hifireads,
                    quast: it.quast ?: params.quast,
                    busco: it.busco ?: params.busco,
                    busco_lineage: it.busco_lineage ?: params.busco_lineage,
                    busco_db: it.busco_db ?: params.busco_db,
                    meryl_k: it.meryl_k ?: params.meryl_k,
                    merqury: it.merqury ?: params.merqury,
                    lift_annotations: (it.ref_gff || params.ref_gff) ? (it.lift_annotations ?: params.lift_annotations) : false,
                    shortread_F: it.shortread_F ?: params.shortread_F,
                    shortread_R: it.shortread_R ?: params.shortread_R,
                    paired: it.paired ?: params.paired ?: ((it.shortread_F || params.shortread_F) && (it.shortread_R || params.shortread_R)) ? true : false,
                    // new:
                    use_short_reads: it.use_short_reads ?: params.use_short_reads ?: params.shortread_F ? true : (it.shortread_F ? true : false),
                    shortread_trim: it.shortread_trim ?: params.shortread_trim
            ]
        ]
        }
    // Define valid hybrid assemblers
    ch_samplesheet.dump(tag: "PARSED INPUTS:")

    emit:
    samplesheet = ch_samplesheet
    versions = ch_versions
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    SUBWORKFLOW FOR PIPELINE COMPLETION
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow PIPELINE_COMPLETION {
    take:
    email //  string: email address
    email_on_fail //  string: email address sent on pipeline failure
    plaintext_email // boolean: Send plain-text email instead of HTML
    outdir //    path: Path to output directory where results will be published
    monochrome_logs // boolean: Disable ANSI colour codes in log output

    main:
    summary_params = paramsSummaryMap(workflow, parameters_schema: "nextflow_schema.json")

    //
    // Completion email and summary
    //
    workflow.onComplete {
        if (email || email_on_fail) {
            completionEmail(
                summary_params,
                email,
                email_on_fail,
                plaintext_email,
                outdir,
                monochrome_logs,
                []
            )
        }

        completionSummary(monochrome_logs)

    }

    workflow.onError {
        log.error "Pipeline failed. Please refer to troubleshooting docs for common issues: https://nf-co.re/docs/running/troubleshooting"
    }
}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

//
// Validate channels from input samplesheet
//
def validateInputSamplesheet(input) {
    def (metas, fastqs) = input[1..2]

    // Check that multiple runs of the same sample are of the same datatype i.e. single-end / paired-end
    def endedness_ok = metas.collect { meta -> meta.single_end }.unique().size == 1
    if (!endedness_ok) {
        error("Please check input samplesheet -> Multiple runs of a sample must be of the same datatype i.e. single-end or paired-end: ${metas[0].id}")
    }

    return [ metas[0], fastqs ]
}
//
// Generate methods description for MultiQC
//
def toolCitationText() {
    def citation_text = [
            "Tools used in the workflow included:",
            "FastQC (Andrews 2010),",
            "."
        ].join(' ').trim()

    return citation_text
}

def toolBibliographyText() {
    def reference_text = [
            "<li>Andrews S, (2010) FastQC, URL: https://www.bioinformatics.babraham.ac.uk/projects/fastqc/).</li>",
        ].join(' ').trim()

    return reference_text
}

def methodsDescriptionText(mqc_methods_yaml) {
    // Convert  to a named map so can be used as with familar NXF ${workflow} variable syntax in the MultiQC YML file
    def meta = [:]
    meta.workflow = workflow.toMap()
    meta["manifest_map"] = workflow.manifest.toMap()

    // Pipeline DOI
    if (meta.manifest_map.doi) {
        // Using a loop to handle multiple DOIs
        // Removing `https://doi.org/` to handle pipelines using DOIs vs DOI resolvers
        // Removing ` ` since the manifest.doi is a string and not a proper list
        def temp_doi_ref = ""
        def manifest_doi = meta.manifest_map.doi.tokenize(",")
        manifest_doi.each { doi_ref ->
            temp_doi_ref += "(doi: <a href=\'https://doi.org/${doi_ref.replace("https://doi.org/", "").replace(" ", "")}\'>${doi_ref.replace("https://doi.org/", "").replace(" ", "")}</a>), "
        }
        meta["doi_text"] = temp_doi_ref.substring(0, temp_doi_ref.length() - 2)
    }
    else {
        meta["doi_text"] = ""
    }
    meta["nodoi_text"] = meta.manifest_map.doi ? "" : "<li>If available, make sure to update the text to include the Zenodo DOI of version of the pipeline used. </li>"

    // Tool references
    meta["tool_citations"] = ""
    meta["tool_bibliography"] = ""

    def methods_text = mqc_methods_yaml.text

    def engine = new groovy.text.SimpleTemplateEngine()
    def description_html = engine.createTemplate(methods_text).make(meta)

    return description_html.toString()
}
