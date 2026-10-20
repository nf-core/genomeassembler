include { quote; sampleId } from '../upstream/modules/utils/main'

process FHR_FINALIZE {
    tag "${meta.id}"
    label 'fhr'

    input:
    tuple val(meta), path(fasta, stageAs: 'sequence/*'), path(yaml, stageAs: 'metadata/*')

    output:
    tuple val(meta), path("${meta.id}.fhr.fasta"), emit: sequence
    tuple val(meta), path("${meta.id}.fhr.yaml"), emit: yaml

    script:
    def id = sampleId(meta)
    """
    cp -- ${quote(fasta)} ${quote("${id}.fhr.fasta")}
    cp -- ${quote(yaml)} ${quote("${id}.fhr.yaml")}
    """
}
