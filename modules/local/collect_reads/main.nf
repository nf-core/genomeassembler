process COLLECT_READS {
    tag "$meta.id"
    label 'process_low'

    conda "conda-forge::python=3.11"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/python:3.11':
        'biocontainers/python:3.11' }"
    input:
    tuple val(meta), path(read_directory)

    output:
    tuple val(meta), path("*.fastq"), emit: combined_reads

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    gunzip -c ${read_directory}/*.gz > ${prefix}_all_reads.fastq
    """
}
