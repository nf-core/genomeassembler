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
    tuple val(meta), path("${assembly}_ragtag_${reference}/*.fasta"), emit: corrected_assembly
    tuple val(meta), path("${assembly}_ragtag_${reference}/*.agp"), emit: corrected_agp
    tuple val(meta), path("${assembly}_ragtag_${reference}/*.stats"), emit: corrected_stats

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
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
        -r

    mv ${prefix}/ragtag.scaffold.fasta ${prefix}/${prefix}.fasta
    mv ${prefix}/ragtag.scaffold.agp ${prefix}/${prefix}.agp
    mv ${prefix}/ragtag.scaffold.stats ${prefix}/${prefix}.stats
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    mkdir ${prefix}
    touch ${prefix}/${prefix}.fasta
    touch ${prefix}/${prefix}.agp
    touch ${prefix}/${prefix}.stats
    """
}
