process MEDAKA {
    tag "$meta.id"
    label 'process_high'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/medaka:1.4.4--py38h130def0_0' :
        'biocontainers/medaka:1.4.4--py38h130def0_0' }"
        
    input:
    tuple val(meta), path(reads), path(assembly)
    val(model)

    output:
    tuple val(meta), path("*.fa.gz"), emit: assembly
    path "versions.yml"             , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def medakamodel = model == '' ? model : "--model ${model}" 
    def NEW_ASSEMBLY = assembly.baseName
    """
    gunzip $assembly
    medaka_consensus \\
        -t $task.cpus \\
        $args \\
        -i $reads \\
        -d $NEW_ASSEMBLY \\
        $medakamodel\\
        -o ./

    mv consensus.fasta ${prefix}_medaka.fa

    gzip -n ${prefix}_medaka.fa

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        medaka: \$( medaka --version 2>&1 | sed 's/medaka //g' )
    END_VERSIONS
    """
}