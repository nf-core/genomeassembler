//
// Subworkflow with functionality specific to the nf-core/genomeassembler pipeline
//

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT FUNCTIONS / MODULES / SUBWORKFLOWS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

include { UTILS_NFSCHEMA_PLUGIN } from '../../nf-core/utils_nfschema_plugin'
include { paramsSummaryMap } from 'plugin/nf-schema'
include { samplesheetToList } from 'plugin/nf-schema'
include { completionEmail } from '../../nf-core/utils_nfcore_pipeline'
include { completionSummary } from '../../nf-core/utils_nfcore_pipeline'
include { imNotification } from '../../nf-core/utils_nfcore_pipeline'
include { UTILS_NFCORE_PIPELINE } from '../../nf-core/utils_nfcore_pipeline'
include { UTILS_NEXTFLOW_PIPELINE } from '../../nf-core/utils_nextflow_pipeline'

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
    outdir //  string: The output directory where the results will be saved
    input //  string: Path to input samplesheet

    main:

    ch_versions = Channel.empty()

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
    UTILS_NFSCHEMA_PLUGIN(
        workflow,
        validate_params,
        null,
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

    Channel.fromPath(params.input)
        .splitCsv(header: true)
        .map { it ->
            [
                meta: [id: it.sample],
                // new in refactor-assemblies
                group: it.group ?: null,
                ontreads: it.ontreads ?: params.ontreads,
                hifireads: it.hifireads ?: params.hifireads,
                // new in refactor-assemblers
                strategy: it.strategy ?: params.strategy,
                assembler: it.assembler ?: params.assembler,
                assembler1: it.assembler1 ?:
                    it.assembler == "hifiasm" || it.assembler == "flye" ? it.assembler :
                    it.assembler.contains("_") ? it.assembler.tokenize("_")[0] :
                    params.assembler == "hifiasm" || params.assembler == "flye" ? params.assembler :
                    params.assembler.contains("_") ? it.assembler.tokenize("_")[0] :
                    null,
                assembler2: it.assembler2 ?:
                    it.assembler.contains("_") ? it.assembler.tokenize("_")[1] :
                    params.assembler.contains("_") ? it.assembler.tokenize("_")[1] :
                    null,
                assembly_scaffolding_order: it.assembly_scaffolding_order ?: params.assembly_scaffolding_order ?: "ont_on_hifi",
                genome_size: it.genome_size ?: params.genome_size,
                assembler1_args: it.assembler1_args ?:
                    (it.assembler1 == "hifiasm") ? params.hifiasm_args :
                    (it.assembler1 == "flye") ? params.flye_args :
                    null,
                assembler2_args: it.assembler2_args ?:
                    (it.assembler2 == "hifiasm") ? params.hifiasm_args :
                    (it.assembler2 == "flye") ? params.flye_args :
                    null,
                polish: it.polish ?:
                    (params.polish_medaka && params.polish_pilon && (it.ontreads || params.ontreads)) ? "medaka+pilon" :
                    (params.polish_medaka && (it.ontreads || params.ontreads)) ? "medaka" :
                    (params.polish_pilon && (it.shortread_F || params.shortread_F)) ? "pilon" :
                    null,
                ont_collect: it.ont_collect ?: params.ont_collect,
                ont_trim: it.ont_trim ?: params.ont_trim,
                ont_adapters: it.ont_adapters ?: params.ont_adapters,
                ont_fastplong_args: it.ont_fastplong_args ?: params.ont_fastplong_args,
                jellyfish: it.jellyfish ?: params.jellyfish,
                jellyfish_k: it.ont_jellyfish_k ?: params.jellyfish_k,
                hifi_trim: it.hifi_trim ?: params.hifi_trim,
                hifi_adapters: it.hifi_adapters ?: params.hifi_adapters,
                hifi_fastplong_args: it.hifi_fastplong_args ?: params.hifi_fastplong_args,
                polish_medaka: it.polish_medaka ?: params.polish_medaka,
                medaka_model: it.medaka_model ?: params.medaka_model,
                polish_pilon: it.polish_pilon ?: params.polish_pilon,
                scaffold_longstitch: it.scaffold_longstitch ?: params.scaffold_longstitch,
                scaffold_links: it.scaffold_longstitch ?: params.scaffold_links,
                scaffold_ragtag: it.scaffold_ragtag ?: params.scaffold_ragtag,
                use_ref: it.use_ref ?: params.use_ref ?: it.ref_fasta ? true : false,
                // not new
                ref_fasta: it.ref_fasta ?: params.ref_fasta,
                ref_gff: it.ref_gff ?: params.ref_gff,
                flye_mode: it.flye_mode ?: params.flye_mode,
                // assembly already provided?
                assembly: it.assembly ?: "",
                // ref mapping provided?
                ref_map_bam: it.ref_map_bam ?: params.ref_map_bam ?: null,
                // assembly mapping provided
                assembly_map_bam: it.assembly_map_bam ?: params.ref_map_bam ?: null,
                // reads for qc
                qc_reads: ((it.qc_reads == "ont" || params.qc_reads == "ont") && it.ontreads) ? "ont" : "hifi",
                qc_reads_path: ((it.qc_reads == "ont" || params.qc_reads == "ont") && it.ontreads) ? (it.ontreads) : (it.hifireads),
                quast: it.quast ?: params.quast,
                busco: it.busco ?: params.busco,
                busco_lineage: it.busco_lineage ?: params.busco_lineage,
                busco_db: it.busco_db ?: params.busco_db,
                meryl_k: it.meryl_k ?: params.meryl_k,
                merqury: it.merqury ?: params.merqury,
                lift_annotations: it.lift_annotations ?: params.lift_annotations,
                shortread_F: it.shortread_F ?: params.shortread_F,
                shortread_R: it.shortread_R ?: params.shortread_R,
                paired: it.paired ?: params.paired,
                // new:
                use_short_reads: it.use_short_reads ?: params.use_short_reads ?: it.shortread_F ? true : false,
                shortread_trim: it.shortread_trim ?: params.shortread_trim
            ] }
        .set { ch_samplesheet }

    // Define valid hybrid assemblers

    def hybrid_assemblers = ["hifiasm"]

    // sample-level checks
    // if a check fails, map returns a list that prints what fails, and contains "invalid"
    // error is raised by subscribe if there is more than one "invalid"
    ch_samplesheet
        .map {
            it ->
            // Check if assembler1 was set
            [(!it.assembler1 && !it.assembly)
                ?
                [
                    println("Please confirm samplesheet: [sample: $it.meta.id]: assembler1 could not be set and no assembly was provided."),
                    "invalid"
                ]
                : null,
            // Check if primers for lima are provided
            (it.hifi_trim && !it.hifi_primers)
                ?
                [
                    println("Please confirm samplesheet: [sample: $it.meta.id]: Please provide the primers used for pacbio sequencing to trim with lima."),
                    "invalid"
                ]
                : null,
            // Check if reads and strategy match
            (it.strategy == "single" && it.ontreads && it.hifireads)
                ?
                [
                    println("Please confirm samplesheet: [sample: $it.meta.id]: Stragety is $it.strategy, but both types of reads are provided."),
                    "invalid"
                ]
                : null,
            // Check if assembler can do hybrid
            (it.strategy == "single" && it.ont_reads && it.hifi_reads)
                ?
                [
                    println("Please confirm samplesheet: [sample: $it.meta.id]: Stragety is $it.strategy, but both types of reads are provided."),
                    "invalid"
                ]
                : null,
            // Check if assembler can do hybrid
            (it.strategy == "single" && it.ont_reads && it.hifi_reads)
                ?
                [
                    println("Please confirm samplesheet: [sample: $it.meta.id]: Stragety is $it.strategy, but both types of reads are provided."),
                    "invalid"
                ]
                : null,
            // Check if assembler can do hybrid
            (it.strategy == "hybrid" && !hybrid_assemblers.contains(it.assembler1))
                ?
                [
                    println("Please confirm samplesheet: [sample: $it.meta.id]: Hybrid assembly can only be performed with $hybrid_assemblers"),
                    "invalid"
                ]
                : null,
            // Check if qc reads are specified for hybrid assemblies
            (it.strategy == "hybrid" && !params.qc_reads)
                ?
                [
                    println("Please confirm samplesheet: [sample: $it.meta.id]: Please specify which reads should be used for qc: '--qc_reads': 'ont' or 'hifi'"),
                    "invalid"
                ]
                : null,
            // Check if genome_size is given with --scaffold_longstitch
            (it.scaffold_longstitch && !it.genome_size && !(params.jellyfish || it.jellyfish))
                ?
                [
                    println("Please confirm samplesheet: [sample: $it.meta.id]: scaffolding with longstitch requires genome-size. Either provide genome-size estimate, or estimate from ONT reads with --jellyfish"),
                    "invalid"
                ]
                : null,
            ]
        }
        .map { it -> it.collect() }
        .collect()
        // error if >0 samples failed a check above
        .subscribe {
            it -> it.contains("invalid")
                ? error("Invalid combination in samplesheet")
                : null
        }

    // Define valid hybrid assemblers

    def hybrid_assemblers = ["hifiasm"]

    // sample-level checks
    // if a check fails, map returns a list that prints what fails, and contains "invalid"
    // error is raised by subscribe if there is more than one "invalid"
    ch_samplesheet
        .map {
            it ->
            // Check if assembler can do hybrid
            (it.strategy == "single" && it.ont_reads && it.hifi_reads)
                ?
                [
                    println("Please confirm samplesheet: [sample: $it.meta.id]: Stragety is $it.strategy, but both types of reads are provided."),
                    "invalid"
                ]
                : null
            // Check if assembler can do hybrid
            (it.strategy == "hybrid" && !hybrid_assemblers.contains(it.assembler1))
                ?
                [
                    println("Please confirm samplesheet: [sample: $it.meta.id]: Hybrid assembly can only be performed with $hybrid_assemblers"),
                    "invalid"
                ]
                : null
            // Check if qc reads are specified for hybrid assemblies
            (it.strategy == "hybrid" && !params.qc_reads)
                ?
                [
                    println("Please confirm samplesheet: [sample: $it.meta.id]: Please specify which reads should be used for qc: '--qc_reads': 'ONT' or 'HIFI'"),
                    "invalid"
                ]
                : null
            // Check if genome_size is given with --scaffold_longstitch
            (params.scaffold_longstitch && !it.genome_size && !(it.ont_reads && params.jellyfish))
                ?
                [
                    println("Please confirm samplesheet: [sample: $it.meta.id]: --scaffold_longstitch requires genome-size. Either provide genome-size estimate, or estimate from ONT reads with --jellyfish"),
                    "invalid"
                ]
                : null
        }
        .collect()
        // error if >0 samples failed a check above
        .subscribe {
            it -> it.contains("invalid")
                ? error("Invalid combination in samplesheet")
                : null
        }

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
    hook_url        //  string: hook URL for notifications

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
        if (hook_url) {
            imNotification(summary_params, hook_url)
        }
    }

    workflow.onError {
        log.error("Pipeline failed. Please refer to troubleshooting docs: https://nf-co.re/docs/usage/troubleshooting")
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
    // TODO nf-core: Optionally add in-text citation tools to this list.
    // Can use ternary operators to dynamically construct based conditions, e.g. params["run_xyz"] ? "Tool (Foo et al. 2023)" : "",
    // Uncomment function in methodsDescriptionText to render in MultiQC report
    def citation_text = [
            "Tools used in the workflow included:",
            "FastQC (Andrews 2010),",
            "."
        ].join(' ').trim()

    return citation_text
}

def toolBibliographyText() {
    // TODO nf-core: Optionally add bibliographic entries to this list.
    // Can use ternary operators to dynamically construct based conditions, e.g. params["run_xyz"] ? "<li>Author (2023) Pub name, Journal, DOI</li>" : "",
    // Uncomment function in methodsDescriptionText to render in MultiQC report
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

    // TODO nf-core: Only uncomment below if logic in toolCitationText/toolBibliographyText has been filled!
    // meta["tool_citations"] = toolCitationText().replaceAll(", \\.", ".").replaceAll("\\. \\.", ".").replaceAll(", \\.", ".")
    // meta["tool_bibliography"] = toolBibliographyText()


    def methods_text = mqc_methods_yaml.text

    def engine = new groovy.text.SimpleTemplateEngine()
    def description_html = engine.createTemplate(methods_text).make(meta)

    return description_html.toString()
}
