process LIFTOFF {
    tag "${meta.id}"
    label 'process_high'

    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container
        ? 'https://depot.galaxyproject.org/singularity/liftoff:1.6.3--pyhdfd78af_0'
        : 'biocontainers/liftoff:1.6.3--pyhdfd78af_0'}"

    input:
    tuple val(meta), path(assembly), path(reference_fasta), path(reference_gff)

    output:
    tuple val(meta), path("*_liftoff.gff"), emit: lifted_annotations

    script:
    """
  if [[ ${assembly} == *.gz ]]; then
    zcat ${assembly} > assembly.fasta
  fi

  if [[ ${assembly} == *.fa || ${assembly} == *.fasta ]]; then
    cp ${assembly} assembly.fasta
  fi

  liftoff \\
    -g ${reference_gff} \\
    -p ${task.cpus} \\
    assembly.fasta  \\
    ${reference_fasta} \\
    -o ${assembly.baseName}_liftoff.gff
    """

    stub:
    def args = task.ext.args ?: ''
    prefix = task.ext.prefix ?: "${meta.id}"
    def touch_polished = args.contains('-polish') ? "touch ${prefix}.polished.gff" : ''
    """
    touch "${prefix}.gff"
    touch "${prefix}.unmapped.txt"
    ${touch_polished}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        liftoff: \$(liftoff --version 2> /dev/null)
    END_VERSIONS
    """
}
