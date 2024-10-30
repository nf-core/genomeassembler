process SAMTOOLS_STATS {
    tag "$meta.id"
    label 'process_low'
    conda "${moduleDir}/../environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/samtools:1.15.1--h1170115_0':
        'biocontainers/samtools:1.15.1--h1170115_0' }"

    conda "bioconda::samtools=1.10" 

    input:
    tuple val(meta), path(bam), path(bai)

    output:
    tuple val(meta), path("*.stats"), emit: stats

    script:
    """
    samtools stats $bam > ${bam}.stats
    """
}
