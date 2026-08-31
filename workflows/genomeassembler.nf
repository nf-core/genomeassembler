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
        .ifEmpty([])

    genomescope_files = PREPARE.out.genomescope_summary
        .mix(
            PREPARE.out.genomescope_plot
        )
        .unique()
        .filter { it -> it != null }
        .collect { it -> it[1] }
        .ifEmpty([])

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

    /*
    Report
    */

    def ch_collated_versions = softwareVersionsToYAML(topic_versions.versions_file)
        .mix(topic_versions_string)

    ch_collated_versions
        .collectFile(
            storeDir: "${params.outdir}/pipeline_info",
            name: 'nf_core_' + 'genomeassembler_software_' + 'versions.yml',
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
        .filter { it -> it[0] != null }
        .unique()
        .collect { reports -> reports[1] }
        .ifEmpty([])

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
        .filter { it -> it != null }
        .collect { reports -> reports[1] }
        .ifEmpty([])

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
        .filter { it -> it != null }
        .collect { reports -> [reports[1], reports[2], reports[3], reports[4]] }
        .toSet()
        .flatten()
        .filter { it -> it != null }
        .collect()
        .ifEmpty([])

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
            ch_collated_versions.collect(),
            ch_main.map { it -> [sample: [id: it.meta.id, group: it.meta.group]] }.collect()
    )

    _report = REPORT.out.report_html.toList()

    /*
    Prepare a samplesheet that is ready to use with nf-core/genomeqc.
    This uses the published output paths, not the workdir files.
    */

    def outdir_uri = file(params.outdir).toUriString()

    def ch_assembly_manifest = ch_main_scaffolded
        .map { it ->
            def meta = it.meta
            def subout =
                    // Assembly publishdirs are a bit more specific
                    meta.strategy == "single" ? (
                        meta.assembler_ont == "flye" || meta.assembler_hifi == "flye"
                            ? 'assembly/flye'
                            : meta.assembler_ont == 'hifiasm'
                                ? 'assembly/hifiasm_ont'
                                : 'assembly/hifiasm'
                    ) :
                    meta.strategy == "hybrid"
                        ? 'assembly/hifiasm'
                        : 'assembly/ragtag'

                // A list of ids, stage, files (in work), the candidate output folder
                [
                [ meta.id, 'scaffold_ragtag', meta.scaffolds ? meta.scaffolds.ragtag ?: null : null,           'scaffold/ragtag'     ],
                [ meta.id, 'scaffold_hic' , meta.scaffolds ? meta.scaffolds.hic ?: null : null,              'scaffold/hic/yahs'   ],
                [ meta.id, 'scaffold_longstitch', meta.scaffolds ? meta.scaffolds.longstitch ?: null : null,       'scaffold/longstitch' ],
                [ meta.id, 'scaffold_links', meta.scaffolds ? meta.scaffolds.links ?: null : null,            'scaffold/links'      ],
                [ meta.id, 'polish_pilon', meta.polished ? meta.polished.pilon ?: null : null,            'polish/pilon'        ],
                [ meta.id, 'polish_medaka', meta.polished ? meta.polished.medaka ?: null : null,           'polish/medaka'       ],
                [ meta.id, 'polish_dorado', meta.polished ? meta.polished.dorado ?: null : null,           'polish/dorado'       ],
                [ meta.id, 'initial_assembly', meta.assembly, subout
                ]
                ]
        }
        .flatMap( { it -> it } )
        .filter {
            _id, _stage,  file, _subdir -> file != null
        }
        .map {
            id, stage ,assembly_file, subdir ->
                [
                    "${id}-${stage}",
                    "${outdir_uri}/${id}/${subdir}/${file(assembly_file).name}"
                ]
        }

    ch_assembly_manifest
        .map {sample, fasta -> [sample,fasta].join(",")}
        .map { rows -> "assembly,fasta\n" + rows + "\n" }
        .collectFile(
            sort: true,
            name: "nf-core-genomeqc-in.csv",
            storeDir: "${params.outdir}/genomeqc_samplesheet",
            keepHeader: true,
            skip: 1
        )


    emit:
    _report
}
