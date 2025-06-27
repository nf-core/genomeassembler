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
<<<<<<< HEAD

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

=======
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
>>>>>>> d2e37c9 (refactor assemble and assemble subworkflows for sample-wise parameterization)
    Channel.empty().set { meryl_kmers }

    Channel.empty().set { ch_versions }

    // Initialize channels for QC report collection
    Channel
        .of([])
        .tap { quast_files }
        .tap { fastplong_reports }
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
            it -> (it.shortread_F && it.use_short_reads) ? true : false
        }
        .set { shortreads }

    ch_main
        .filter {
            it -> (it.ontreads) ? true : false
        }
        .set { ontreads }

    ch_main
        .filter {
            it -> (it.hifireads) ? true : false
        }
        .set { hifireads }

    // adapted to sample-logic
    PREPARE_SHORTREADS(shortreads)

    PREPARE_SHORTREADS.out.meryl_kmers.set { meryl_kmers }
    // This changes ch_main shortreads_F and _R become one tuple, paired is gone.

    // put shortreads back together with samples without shortreads

    ch_main
        .filter {
            it -> !it.shortread_F ? true : false
        }
        .map { it -> it - it.subMap("shortread_F","shortread_R", "paired") + [shorteads: null] }
        .mix(PREPARE_SHORTREADS.out.main_out)
        .set { ch_main_shortreaded }

    ONT(ontreads)
    ONT.out.main_out.set { ch_main_ont_prepped }

    HIFI(hifireads)
    HIFI.out.main_out.set { ch_main_hifi_prepped }

    // rebuild the main channel from shortread out, ont out and hifi out.
    // This will block entry into assemble, and it should.


    // ch_main_shortreaded contains all samples
    // add ONT outputs to mixed shortread output

    ch_main_shortreaded
        .filter {
            it -> it.ontreads ? true : false
        }
        .map { it -> it.subMap("meta","shortreads")}
        .map { it -> it.collect { entry -> [ entry.value, entry ] } }
            .join( ch_main_ont_prepped
                    .map { it -> it - it.subMap("shortreads") }
                    .map { it -> it.collect { entry -> [ entry.value, entry ] } }
            )
            // After joining re-create the maps from the stored map
        .map { it -> it.collect { _entry, map -> [ (map.key): map.value ] }.collectEntries() }
        // mix back in those samples where nothing was done to the ont reads
        .mix(ch_main_shortreaded
            .filter {
                it -> it.ontreads ? false : true
            }
        )
        .set {
            ch_main_sr_ont
        }

    // Add prepared hifi-reads:

    ch_main_sr_ont
        .filter {
            it -> it.hifireads ? true : false
        }
        .map { it -> it.subMap("meta","shortreads","ontreads")}
        .map { it -> it.collect { entry -> [ entry.value, entry ] } }
            .join( ch_main_hifi_prepped
                    .map { it -> it - it.subMap("shortreads","ontreads") }
                    .map { it -> it.collect { entry -> [ entry.value, entry ] } }
            )
            // After joining re-create the maps from the stored map
        .map { it -> it.collect { _entry, map -> [ (map.key): map.value ] }.collectEntries() }
        // mix back in those samples where nothing was done to the hifireads reads
        .mix(ch_main_sr_ont
            .filter {
                it -> it.hifireads ? false : true
            }
        )
        .set {
            ch_main_prepared
        }

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

    ch_versions = ch_versions.mix(PREPARE_SHORTREADS.out.versions).mix(ONT.out.versions).mix(HIFI.out.versions).mix(ASSEMBLE.out.versions).mix(POLISH.out.versions).mix(SCAFFOLD.out.versions)

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
            fasplong_jsons,
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
