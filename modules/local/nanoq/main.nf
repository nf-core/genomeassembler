process NANOQ {
    tag "${meta.id}"
    label 'process_low'
    conda "${moduleDir}/environment.yml"

    container "${workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container
        ? 'https://depot.galaxyproject.org/singularity/nanoq:0.10.0--h031d066_2'
        : 'biocontainers/nanoq:0.10.0--h031d066_2'}"

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("*_report.json"), emit: report
    tuple val(meta), path("*_stats.json"), emit: stats
    tuple val(meta), env(median), emit: median_length

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    nanoq -i ${reads} -j -r ${prefix}_report.json -s -H -vvv > ${prefix}_stats.json
    median=\$(cat ${prefix}_report.json | grep -o '"median_length":[0-9]*' | grep -o '[0-9]*')
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}_report.json
    touch ${prefix}_stats.json
    median=1

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        nanoq: \$(nanoq -V 2>&1)
    END_VERSIONS
    """
}
