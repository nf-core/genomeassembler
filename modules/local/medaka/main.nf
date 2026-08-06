process MEDAKA {
    tag "${meta.id}"
    label 'process_high_cpu'
    label 'process_high_memory'
    label 'process_long'

    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container
        ? 'https://depot.galaxyproject.org/singularity/medaka:1.11.3--py310h87e71ce_0'
        : 'biocontainers/medaka:1.11.3--py310h87e71ce_0'}"

    input:
    tuple val(meta), path(reads), path(assembly)

    output:
    tuple val(meta), path("*_medaka.fa.gz"), emit: assembly
    tuple val("${task.process}"), val('medaka'), eval("medaka --version 2>&1 | sed 's/medaka //g'"), emit: versions_medaka, topic: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    assembly=${assembly}
    if [[ ${assembly} == *.gz ]]; then
        gunzip ${assembly}
        assembly=\$(basename \$assembly .gz)
    fi
    medaka_consensus \\
        -t ${task.cpus} \\
        ${args} \\
        -i ${reads} \\
        -d \$assembly \\
        -o ./

    mv consensus.fasta ${prefix}.fa

    gzip -n ${prefix}.fa
    """
    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}_medaka.fa.gz
    """
}
