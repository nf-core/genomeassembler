process SAMTOOLS_FASTQ {
    tag "$meta.id"
    label 'process_low'
    conda "${moduleDir}/../environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/samtools:1.15.1--h1170115_0':
        'biocontainers/samtools:1.15.1--h1170115_0' }"
    publishDir(
      path: { "${params.out}/${task.process}".replace(':','/').toLowerCase() }, 
      mode: 'copy',
      overwrite: true,
      saveAs: { fn -> fn.substring(fn.lastIndexOf('/')+1) }
    ) 
    input:
    tuple val(meta), path(bam), path(bai)

    output:
    tuple val(meta), path("*.fq.gz"), emit: fasta

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    samtools fastq $bam | gzip | ${prefix}.fq.gz
    """
}
