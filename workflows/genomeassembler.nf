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
include { SCAFFOLD                  } from '../subworkflows/local/scaffold/main'

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
    ch_main = ch_input

    /*
    This pipeline uses a "meta-stuffing" appraoch. All information
    about a sample is always stored in a map stored in [0]/"meta".
    Values are extracted from the map to create input channels.
    The correspoding key is created or updated from outputs.
    This largely eliminates the need for joins.

    The initial keys are defined in
    ./subworkflows/local/utils_nfcore_genomeassembler/main.nf
    */
    meryl_kmers = channel.empty()

    // Initialize channels for QC report collection
    quast_files = channel.of([])
    fastplong_jsons = channel.of([])
    genomescope_files = channel.of([])
    busco_files = channel.of([]).map { it -> ["dummy", it] }
    merqury_files = channel.of([]).map { it -> [it[0], it[1], it[1], it[1], it[1]] }

    /*
    =============
    Prepare reads
    =============
    */
    PREPARE(ch_main)

    ch_main_prepared = PREPARE.out.ch_main

    meryl_kmers = PREPARE.out.meryl_kmers

    /*
    Assembly
    */
    // This pipeline is named genomeassembler, so everything goes into assemble
    // even it might not actually be assembled.

    ASSEMBLE(ch_main_prepared, meryl_kmers)

    ch_main_assembled = ASSEMBLE.out.ch_main

    /*
    Polishing
    */
    ch_main_assembled_branched = ch_main_assembled
        .branch {
            it ->
            def polishers = ["pilon", "medaka", "medaka+pilon", "dorado", "dorado+pilon"]
            polish:     polishers.contains(it.meta.polish)
            no_polish:  true
        }

    POLISH(ch_main_assembled_branched.polish, meryl_kmers)

    ch_main_polished = ch_main_assembled_branched.no_polish
        .mix(POLISH.out.ch_main)
    // Update scaffold for meta map

    ch_main_polished_branched = ch_main_polished
        .branch { it ->
            scaffold: it.meta.scaffold_links || it.meta.scaffold_longstitch || it.meta.scaffold_ragtag || it.meta.scaffold_hic
            no_scaffold: !it.meta.scaffold_links && !it.meta.scaffold_longstitch && !it.meta.scaffold_ragtag && !it.meta.scaffold_hic
        }

    /*
    Scaffolding
    */
    SCAFFOLD(ch_main_polished_branched.scaffold, meryl_kmers)

    // Recreate ch_main, even though it is not used since there are no later steps.

    ch_main_scaffolded = ch_main_polished_branched
        .no_scaffold
        .mix(SCAFFOLD.out.ch_main)

    fastplong_jsons = PREPARE.out.fastplong_json_reports
        .map { it -> it[1] }
        .unique()
        .collect()

    genomescope_files = PREPARE.out.genomescope_summary
        .concat(
            PREPARE.out.genomescope_plot
        )
        .unique()
        .collect { it -> it[1] }

    def topic_versions = channel.topic("versions")
      .distinct()
      .branch { entry ->
          versions_file: entry instanceof Path
          versions_tuple: true
      }

    def topic_versions_string = topic_versions.versions_tuple
      .map { process, tool, version ->
          [ process[process.lastIndexOf(':')+1..-1], "  ${tool}: ${version}" ]
      }
      .groupTuple(by:0)
      .map { process, tool_versions ->
          tool_versions.unique().sort()
          "${process}:\n${tool_versions.join('\n')}"
      }
    ch_collated_versions = topic_versions_string
    /*
    Report
    */
    ch_collated_versions
        .collectFile(
            storeDir: "${params.outdir}/pipeline_info",
            name: 'nf_core_' + 'pipeline_software_' + 'versions.yml',
            sort: true,
            newLine: true
        )

    quast_files = quast_files
        .mix(
            ASSEMBLE.out.assembly_quast_reports
            .mix(
                POLISH.out.polish_quast_reports
            )
            .mix(
                SCAFFOLD.out.scaffold_quast_reports
            )
        )
        .unique()
        .collect()

    busco_files = busco_files
        .mix(
            ASSEMBLE.out.assembly_busco_reports
            .mix(
                POLISH.out.polish_busco_reports
            )
            .mix(
                SCAFFOLD.out.scaffold_busco_reports
            )
        )
        .unique()
        .collect { it -> it[1] }

    merqury_files = merqury_files
        .mix(
            ASSEMBLE.out.assembly_merqury_reports
            .mix(
                POLISH.out.polish_merqury_reports
            )
            .mix(
                SCAFFOLD.out.scaffold_merqury_reports
            )
        )
        .collect { it -> [it[1], it[2], it[3], it[4]] }
        .toSet()
        .flatten()
        .collect()

    report_files = channel
        .fromPath("${projectDir}/assets/report/*")
        .collect()
    // Report files
    report_functions = channel
        .fromPath("${projectDir}/assets/report/functions/*")
        .collect()

    report_scripts = channel
        .fromPath("${projectDir}/assets/report/scripts/*")
        .collect()

    REPORT( report_files,
            report_functions,
            report_scripts,
            fastplong_jsons,
            genomescope_files,
            quast_files,
            busco_files,
            merqury_files,
            channel.fromPath("${params.outdir}/pipeline_info/nf_core_pipeline_software_versions.yml"),
            ch_main.map { it -> [sample: [id: it.meta.id, group: it.meta.group]] }.collect()
    )

    _report = REPORT.out.report_html.toList()

    emit:
    _report
}
