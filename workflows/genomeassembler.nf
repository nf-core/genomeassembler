/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
include { paramsSummaryMap          } from 'plugin/nf-schema'
include { paramsSummaryMultiqc      } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { softwareVersionsToYAML    } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { methodsDescriptionText    } from '../subworkflows/local/utils_nfcore_genomeassembler_pipeline'

// Read preparation
include { PREPARE                   } from '../subworkflows/local/prepare/main'

// Assembly
include { ASSEMBLE                  } from '../subworkflows/local/assemble/main'

// Polishing
include { POLISH                    } from '../subworkflows/local/polishing/main'

// Scaffolding
include { SCAFFOLD                  } from '../subworkflows/local/scaffolding/main'

// reporting
include { REPORT                    } from '../modules/local/report/main'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow GENOMEASSEMBLER {
    take:
    ch_input

    main:
    // Initialize empty channels
    ch_input.set { ch_main }

    /*

    The "main" channel, contains all sample-wise information.
    This channel should be the main input of all subworkflows
    and the subworkflows should make changes to this map. The
    main channel should stay a map whenever possible and this
    main channel reflects all pipeline parameters.
    I will make use of the meta map to pass additional infor-
    mation into processes. This is neccessary to provide fine
    control for parameterization of processes. This is passed
    via ext.args to the process and fetched from meta.

    The keys are defined in
    ./subworkflows/local/utils_nfcore_genomeassembler/main.nf

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
        assembly: path,
        ref_map_bam: path,
        assembly_map_bam: path,
        qc_reads: string ["ont","hifi"],
        qc_reads_path: path,
        quast: bool,
        busco: bool,
        busco_lineage: string,
        busco_db: path,
        lift_annotations: bool,
        shortread_F: path,
        shortread_R: path,
        paired: bool,
        use_short_reads: bool,
        shortread_trim: bool
    */

    // TODO: Currently the pipeline is losing everything with hifireads somewhere.

    Channel.empty().set { meryl_kmers }

    Channel.empty().set { ch_versions }

    // Initialize channels for QC report collection
    Channel
        .of([])
        .tap { quast_files }
        .tap { fastplong_files }
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
    PREPARE(ch_main)

    PREPARE.out.ch_main.set { ch_main_prepared }

    PREPARE.out.meryl_kmers.set { meryl_kmers }

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

    PREPARE.out.nanoq_report
        .concat(
            PREPARE.out.nanoq_stats
        )
        .collect { it -> it[1] }
        .set { nanoq_files }

    PREPARE.out.genomescope_summary
        .concat(
            PREPARE.out.genomescope_plot
        )
        .unique()
        .collect { it -> it[1] }
        .set { genomescope_files }

    ch_versions = ch_versions.mix(PREPARE.out.versions).mix(ASSEMBLE.out.versions).mix(POLISH.out.versions).mix(SCAFFOLD.out.versions)

    ch_versions = ch_versions



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

    }

    ch_main
        .collect { it -> it.quast ?: null }
        .map { it -> it.any { it2 -> it2 == true ?: false } }
        .set { quast_val }
    ch_main
        .collect { it -> it.busco ?: null }
        .map { it -> it.any { it2 -> it2 == true ?: false } }
        .set { busco_val }
    ch_main
        .collect { it -> it.ont_jellyfish ?: null }
        .map { it -> it.any { it2 -> it2 == true ?: false } }
        .set { jelly_val }
    ch_main
        .collect { it -> it.merqury ?: null }
        .map { it -> it.any { it2 -> it2 == true ?: false } }
        .set { merqury_val }

    REPORT( report_files,
            report_functions,
            nanoq_files,
            genomescope_files,
            quast_files,
            busco_files,
            merqury_files,
            Channel.fromPath("${params.outdir}/pipeline_info/nf_core_pipeline_software_versions.yml"),
            ch_main.map { it -> [sample: [id: it.meta.id, group: it.group]]}.collect()
    )

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
