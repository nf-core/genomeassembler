process RAGTAG_SCAFFOLD {
    tag "${meta.id}"
    label 'process_high'
    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container
        ? 'https://depot.galaxyproject.org/singularity/ragtag:2.1.0--pyhb7b1952_0'
        : 'biocontainers/ragtag:2.1.0--pyhb7b1952_0'}"

    input:
    tuple val(meta), path(assembly), path(reference)

    output:
    tuple val(meta), path("*.fasta"), emit: corrected_assembly
    tuple val(meta), path("*.agp"),   emit: corrected_agp
    tuple val(meta), path("*.stats"), emit: corrected_stats
    path "versions.yml", emit: versions

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    def args = task.ext.args ?: ""
    """
    if [[ ${assembly} == *.gz ]]
    then
        zcat ${assembly} > assembly.fa
    else
        mv ${assembly} assembly.fa
    fi

    ragtag.py scaffold ${reference} assembly.fa \\
        -o "${prefix}" \\
        -t ${task.cpus} \\
        -f 5000 \\
        -w \\
        -C \\
        -u \\
        -r \\
        $args

    mv ${prefix}/ragtag.scaffold.fasta ${prefix}.fasta
    mv ${prefix}/ragtag.scaffold.agp ${prefix}.agp
    mv ${prefix}/ragtag.scaffold.stats ${prefix}.stats

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        RagTag: \$(echo \$(ragtag.py -v | sed 's/v//'))
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.fasta
    touch ${prefix}.agp
    touch ${prefix}.stats
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        RagTag: \$(echo \$(ragtag.py -v | sed 's/v//'))
    END_VERSIONS
    """
}
