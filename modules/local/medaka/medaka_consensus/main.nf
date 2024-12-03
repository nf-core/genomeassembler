process MEDAKA_PARALLEL {
    tag "${meta.id}"
    label 'process_high'
    label 'process_long'

    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container
        ? 'https://depot.galaxyproject.org/singularity/biocontainers/medaka:2.0.1--py310he807b20_0'
        : 'biocontainers/medaka:2.0.1--py310he807b20_0'}"

    input:
    tuple val(meta), path(reads), path(assembly)

    output:
    tuple val(meta), path("*_medaka.fa.gz"), emit: assembly
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args1 = task.ext.args1 ?: ''
    def args2 = task.ext.args2 ?: ''
    def args3 = task.ext.args3 ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    assembly=${assembly}
    if [[ ${assembly} == *.gz ]]; then
        gunzip ${assembly}
        assembly=\$(basename \$assembly .gz)
    fi

    mini_align \\
        -i ${reads} \\
        -r \$assembly \\
        -P -m \\
        -t $task.cpus \\
        -p ${prefix}_calls_to_draft \\
          ${args1}

    # In medaka >= 2.0 this step is medaka inference, in earlier versions it is consensus
    mkdir inference
    # Start with the largest contigs, they probably take longest
    sort -nrk2 \${assembly}.fai \\
     | cut -f1 \\ 
     | xargs \\
       -P \$((${task.cpus}-4)) \\
       -n1 \\
       -I{} \\
         medaka inference ${prefix}_calls_to_draft.bam \\
           inference/{}.hdf \\
           --region {} \\
           ${args2}

    # In medaka >= 2.0 this step is medaka sequence, in earlier versions it is stitch
    medaka sequence \\
          ${args3} \\
          inference/*.hdf ${prefix}.fa

    gzip -n ${prefix}.fa

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        medaka: \$( medaka --version 2>&1 | sed 's/medaka //g' )
    END_VERSIONS
    """
}
