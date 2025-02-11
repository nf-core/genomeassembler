process LINKS {
    tag "${meta.id}"
    label 'process_high'

    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container
        ? 'https://depot.galaxyproject.org/singularity/links:2.0.1--h4ac6f70_5'
        : 'biocontainers/links:2.0.1--h4ac6f70_5'}"

    input:
    tuple val(meta), path(assembly), path(reads)

    output:
    tuple val(meta), path("*.scaffolds.fa"), emit: scaffolds
    tuple val(meta), path("*.scaffolds"), emit: scaffold_csv
    tuple val(meta), path("*.gv"), emit: graph
    tuple val(meta), path("*.log"), emit: log

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    echo "${reads}" > readfile.fof
    LINKS -f ${assembly} -s readfile.fof -j 3 -b ${prefix}_links -t 40,200 -d 500,2000,5000
    sed -i 's/\\(scaffold[0-9]*\\).*/\\1/' ${prefix}_links.scaffolds.fa
    """
    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}_links.scaffolds.fa
    touch ${prefix}_links.scaffolds
    touch ${prefix}.gv
    touch ${prefix}.log
    """
}
