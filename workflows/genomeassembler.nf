/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
include { FASTQC                 } from '../modules/nf-core/fastqc/main'
include { MULTIQC                } from '../modules/nf-core/multiqc/main'
include { paramsSummaryMap       } from 'plugin/nf-schema'
include { paramsSummaryMultiqc   } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { softwareVersionsToYAML } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { methodsDescriptionText } from '../subworkflows/local/utils_nfcore_genomeassembler_pipeline'
// Read preparation
include { PREPARE_ONT            } from '../subworkflows/local/prepare_ont/main'
include { PREPARE_HIFI           } from '../subworkflows/local/prepare_hifi/main'
include { PREPARE_SHORTREADS     } from '../subworkflows/local/prepare_shortreads/main'

// Read checks
include { ONT                    } from '../subworkflows/local/ont/main'
include { HIFI                   } from '../subworkflows/local/hifi/main'

// Assembly 
include { ASSEMBLE               } from '../subworkflows/local/assemble/main'

// Polishing
include { POLISH                 } from '../subworkflows/local/polishing/main'


// Scaffolding
include { SCAFFOLD               } from '../subworkflows/local/scaffolding/main'
// reporting
include { REPORT                } from '../modules/local/report/main'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow GENOMEASSEMBLER {

    take:
        ch_input
        ch_refs
    /*
    Define channels
    */
    main:

    Channel.empty().set { ch_ref_bam }
    Channel.empty().set { ch_assembly }
    Channel.empty().set { ch_assembly_bam }
    Channel.empty().set { ch_assembly_bam_bai }
    Channel.empty().set { ch_medaka_in }
    Channel.empty().set { ch_polished_genome }
    Channel.empty().set { ch_ont_reads }
    Channel.empty().set { ch_hifi_reads }
    Channel.empty().set { ch_shortreads }
    Channel.empty().set { meryl_kmers }
    Channel.empty().set { ch_flye_inputs }
    Channel.empty().set { ch_hifiasm_inputs }
    Channel.empty().set { genome_size }
    Channel.empty().set { ch_versions }

    Channel
        .fromPath("$projectDir/assets/report/.DUMMYFILE") // quast emits a single file
        .tap { quast_files }
        .tap { nanoq_files }
        .tap { genomescope_files }
        .map { it -> ["dummy", it] } // busco emits meta and a file
        .tap { busco_files }
        .map { it -> [it[0], it[1], it[1], it[1], it[1]]} // merqury emits meta + 4 files
        .tap { merqury_files }
    /*
    =============
    Some checks
    =============
    */  
    if(!params.ont && !params.hifi) error 'At least one of params.ont, params.hifi needs to be true.'
    /*
    =============
    Prepare reads
    =============
    */
    /*
    Short reads
    */
    if(params.short_reads) {
        PREPARE_SHORTREADS(ch_input)
        PREPARE_SHORTREADS
            .out
            .shortreads
            .set { ch_shortreads }
        PREPARE_SHORTREADS
            .out
            .meryl_kmers
            .set { meryl_kmers }
    }


    /*
    ONT reads
    */
    if(params.ont) {
        ONT(ch_input)
        ONT
            .out
            .genome_size
            .set { genome_size }
        ONT
            .out
            .ont_reads
            .set { ch_ont_reads }

        ONT
            .out
            .nanoq_report
            .concat(
                ONT
                    .out
                    .nanoq_stats
            )
            .collect { it -> it[1] }
            .set { nanoq_files }
        ONT
            .out
            .genomescope_summary
            .concat(
                ONT
                    .out
                    .genomescope_plot
            )
            .unique()
            .collect { it -> it[1] }
            .set { genomescope_files }
    } 


    /*
    HIFI reads
    */
    if(params.hifi) {
        HIFI(ch_input)
        HIFI
            .out
            .hifi_reads
            .set { ch_hifi_reads }
    }

    /*
    Assembly
    */

    ASSEMBLE(ch_ont_reads, ch_hifi_reads, ch_input, genome_size, meryl_kmers)
    ASSEMBLE
      .out
      .assembly
      .set { ch_polished_genome }
    ASSEMBLE
      .out
      .ref_bam
      .set { ch_ref_bam }
    ASSEMBLE
      .out
      .longreads
      .set { ch_longreads }
    
    /*
    Polishing
    */

    POLISH(ch_input, ch_ont_reads, ch_longreads, ch_shortreads, ch_polished_genome, ch_ref_bam, meryl_kmers)
    POLISH
      .out
      .ch_polished_genome
      .set { ch_polished_genome }

    /*
    Scaffolding
    */
    
    SCAFFOLD(ch_input, ch_longreads, ch_polished_genome, ch_refs, ch_ref_bam, meryl_kmers)

    /*
    Report
    */
        
    quast_files
        .concat(
            ASSEMBLE
                .out
                .assembly_quast_reports
                .concat(
                    POLISH
                        .out
                        .polish_quast_reports
                )
                .concat(
                    SCAFFOLD
                        .out
                        .scaffold_quast_reports
                )
        )
        .unique()
        .collect()
        .set { quast_files }

    busco_files
        .concat(
            ASSEMBLE
                .out
                .assembly_busco_reports
                .concat(
                    POLISH
                        .out
                        .polish_busco_reports
                )
                .concat(
                    SCAFFOLD
                        .out
                        .scaffold_busco_reports
                )
        )
        .unique()
        .collect { it -> it[1] } // Keep only files
        .set { busco_files }

    merqury_files
        .concat(
            ASSEMBLE
                .out
                .assembly_merqury_reports
                .concat(
                    POLISH
                        .out
                        .polish_merqury_reports
                )
                .concat(
                    SCAFFOLD
                        .out
                        .scaffold_merqury_reports
                )
        )
        .collect { it -> [it[1], it[2], it[3], it[4]] } // Keep only files: [stats, spectra, copynumber, qv]
        // I am unable to get uniques via .unique() on the list, this is a workaround
        .toSet()
        .flatten()
        .collect()
        // set channel
        .set { merqury_files }

    Channel.fromPath("$projectDir/assets/report/*")
        .collect()
        .set { report_files } // Report files
    Channel.fromPath("$projectDir/assets/report/functions/*")
        .collect()
        .set { report_functions } // Report functions, mainly parsers
    /* Debug         
    report_files.view { f -> "Report Files: $f"}
    report_functions.view { f -> "Report Functions: $f"}
    nanoq_files.view { f -> "Nanoq Files: $f"}
    genomescope_files.view { f -> "Genomescope Files: $f"}
    quast_files.view { f -> "QUAST Files: $f"}
    busco_files.view { f -> "BUSCO Files: $f"}
    merqury_files.view { f -> "merqury Files: $f"}
    */ 
    // TODO: Update report to include merqury qv!
    REPORT(report_files, report_functions, nanoq_files, genomescope_files, quast_files, busco_files, merqury_files)
    
    //
    // Collate and save software versions
    //
    softwareVersionsToYAML(ch_versions)
        .collectFile(
            storeDir: "${params.outdir}/pipeline_info",
            name: 'nf_core_'  + 'pipeline_software_' +  'mqc_'  + 'versions.yml',
            sort: true,
            newLine: true
        ).set { ch_collated_versions }

    _report = REPORT.out.report_html.toList() 
    //Channel.empty().set { _report }

    emit:
    _report 
    versions       = ch_versions                 // channel: [ path(versions.yml) ]
}
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
