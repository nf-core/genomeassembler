process MEDAKA {
    tag "$meta"
    label 'process_high'
    conda "bioconda::medaka=1.11.1"
    publishDir(
      path: { "${params.out}/${task.process}".replace(':','/').toLowerCase() }, 
      mode: 'copy',
      overwrite: true,
      saveAs: { fn -> fn.substring(fn.lastIndexOf('/')+1) }
    ) 

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
    def prefix = task.ext.prefix ?: "${meta}"
    def NEW_ASSEMBLY = assembly.baseName
    """
    gunzip $assembly
    medaka_consensus \\
        -t $task.cpus \\
        $args \\
        -i $reads \\
        -d $NEW_ASSEMBLY \\
        -m $model\\
        -o ./

    mv consensus.fasta ${prefix}_medaka.fa

    gzip -n ${prefix}_medaka.fa

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        medaka: \$( medaka --version 2>&1 | sed 's/medaka //g' )
    END_VERSIONS
    """
}