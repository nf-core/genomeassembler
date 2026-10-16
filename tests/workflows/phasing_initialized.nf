include { PIPELINE_INITIALISATION } from '../../subworkflows/local/utils_nfcore_genomeassembler_pipeline/main'
include { GENOMEASSEMBLER } from '../../workflows/genomeassembler'

workflow PHASING_INITIALIZED {
    take:
    samplesheet

    main:
    PIPELINE_INITIALISATION(false, false, true, [], params.outdir, samplesheet, false, false, false)
    GENOMEASSEMBLER(PIPELINE_INITIALISATION.out.samplesheet)

    emit:
    samples = PIPELINE_INITIALISATION.out.samplesheet
    assemblies = GENOMEASSEMBLER.out.assemblies
}
