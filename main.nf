#!/usr/bin/env nextflow
/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    nf-core/genomeassembler
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    Github : https://github.com/nf-core/genomeassembler
    Website: https://nf-co.re/genomeassembler
    Slack  : https://nfcore.slack.com/channels/genomeassembler
----------------------------------------------------------------------------------------
*/
#!/usr/bin/env nextflow

/*
Parameter setup
*/
nextflow.enable.dsl = 2 
params.publish_dir_mode = 'copy'
params.samplesheet = false
params.enable_conda = false
params.collect = false
params.porechop = false
//Jellyfish params
params.jelly_is_reads = true
params.kmer_length = 21
params.read_length = null
params.dump = false

//
params.use_ref = true
params.skip_flye = false
params.genome_size = null
params.flye_mode = '--nano-hq'
params.flye_args = ''
params.polish_pilon = false
params.polish_medaka = true
params.medaka_model = 'r1041_e82_400bps_hac_v4.2.0'
params.skip_alignments = false
params.scaffold_ragtag = false
params.scaffold_links = false
params.scaffold_longstitch = false
params.lift_annotations = true
params.busoc_db = "/dss/dsslegfs01/pn73so/pn73so-dss-0000/becker_common/software/busco_db"
params.busco_lineage = "brassicales_odb10"
params.out = './results'

/*
 Print very cool text and parameter info to log. 
*/

log.info """\
======================================================================================================================================================
======================================================================================================================================================
nf-co.re/genomeassembler     
------------------------------------------------------------------------------------------------------------------------------------------------------
                                                                   
------------------------------------------------------------------------------------------------------------------------------------------------------
  Results directory  : ${params.out}

  Parameters:
     samplesheet     : ${params.samplesheet}
     collect         : ${params.collect}
     porechop        : ${params.porechop}
     read_length     : ${params.read_length}
     genome_size     : ${params.genome_size}
     flye_mode       : ${params.flye_mode}
     polish_medaka   : ${params.polish_medaka}
     medaka_model    : ${params.medaka_model}
     polish_pilon    : ${params.polish_pilon}
     busco db        : ${params.busoc_db}
     busco lineage   : ${params.busco_lineage}
     use reference   : ${params.use_ref}

    Scaffolding Tools
     ragtag          : ${params.scaffold_ragtag}
     LINKS           : ${params.scaffold_links}
     longstitch      : ${params.scaffold_longstitch}

    Annotation lift  : ${params.lift_annotations}

    Steps skipped
     skip_flye       : ${params.skip_flye}
     skip_alignments : ${params.skip_alignments}
======================================================================================================================================================
======================================================================================================================================================
"""
    .stripIndent(false)

include { ASSEMBLE } from './subworkflows/main'

workflow {
  ASSEMBLE()
}