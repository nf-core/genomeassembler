process MEDAKA {
    tag "$meta.id"
    label 'process_high'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/medaka:2.0.1--py311hfd2b166_0' :
        'biocontainers/medaka:2.0.1--py311hfd2b166_0' }"
        
    input:
    tuple val(meta), path(reads), path(assembly)

    output:
    tuple val(meta), path("*_medaka.fa.gz"), emit: assembly
    path "versions.yml"             , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    assembly=$assembly
    if [[ $assembly == *.gz ]]; then
        gunzip $assembly
        assembly=\$(basename \$assembly .gz)
    fi
    medaka_consensus \\
        -t $task.cpus \\
        $args \\
        -i $reads \\
        -d \$assembly \\
        -o ./

    mv consensus.fasta ${prefix}_medaka.fa

    gzip -n ${prefix}_medaka.fa

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        medaka: \$( medaka --version 2>&1 | sed 's/medaka //g' )
    END_VERSIONS
    """
}