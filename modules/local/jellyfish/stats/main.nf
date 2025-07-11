process STATS {
    tag "${meta.id}"
    label 'process_medium'
    container "${workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container
        ? 'https://depot.galaxyproject.org/singularity/kmer-jellyfish:2.3.1--h4ac6f70_0'
        : 'biocontainers/kmer-jellyfish:2.3.1--h4ac6f70_0'}"

    input:
    tuple val(meta), path(kmers)

    output:
    tuple val(meta), path("*.txt"), emit: stats
    path "versions.yml", emit: versions


    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    jellyfish stats ${kmers} > ${prefix}_stats.txt
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        jellyfish: \$(echo \$(jellyfish --version sed 's/jellyfish //'))
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}_stats.txt
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        jellyfish: \$(echo \$(jellyfish --version sed 's/jellyfish //'))
    END_VERSIONS
    """
}
