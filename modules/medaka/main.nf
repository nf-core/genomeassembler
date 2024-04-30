include { initOptions; saveFiles; getSoftwareName } from './functions'

params.options = [:]
options        = initOptions(params.options)

process MEDAKA {
    tag "$meta"
    label 'process_high'

    conda "bioconda::medaka=1.11.1"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/1.8.0--py38hdaa7744_0' :
        'quay.io/biocontainers/medaka:1.11.3--py310h87e71ce_0' }"
        
    publishDir "${params.out}",
        mode: params.publish_dir_mode,
        saveAs: { filename -> saveFiles(filename:filename,
                                        options:params.options, 
                                        publish_dir:"${task.process}".replace(':','/').toLowerCase(), 
                                        publish_id:meta) }
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