process SAMTOOLS_SORT {
    tag "$meta"
    label 'process_medium'
    conda "bioconda::samtools=1.10"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/ragtag:1.15.1--h1170115_0':
        'biocontainers/samtools:1.15.1--h1170115_0' }"
    publishDir(
      path: { "${params.out}/${task.process}".replace(':','/').toLowerCase() }, 
      mode: 'copy',
      overwrite: true,
      saveAs: { fn -> fn.substring(fn.lastIndexOf('/')+1) }
    ) 
    conda "bioconda::samtools=1.10" 

    input:
    tuple val(meta), path(bam)

    output:
    tuple val(meta), path("*.bam"), emit: bam

    script:
    def prefix   = options.suffix ? "${meta}${options.suffix}" : "${meta}"
    """
    samtools sort $options.args -@ $task.cpus -o ${prefix}.bam -T $prefix $bam
    """
}
