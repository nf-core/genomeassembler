process SAMTOOLS_INDEX {
    tag "$meta.id"
    label 'process_low'
    conda "${moduleDir}/../environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/samtools:1.15.1--h1170115_0':
        'biocontainers/samtools:1.15.1--h1170115_0' }"

    conda "bioconda::samtools=1.10" 

    input:
    tuple val(meta), path(bam)

    output:
    tuple val(meta), path("*.bai"), emit: bai

    script:
    """
    samtools index $bam
    """
}
