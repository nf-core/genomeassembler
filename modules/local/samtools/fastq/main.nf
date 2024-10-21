process SAMTOOLS_FASTQ {
    tag "$meta"
    label 'process_low'
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
    input:
    tuple val(meta), path(bam), path(bai)

    output:
    tuple val(meta), path("*.fq.gz"), emit: fasta

    script:
    """
    samtools fastq $bam | gzip | ${meta}.fq.gz
    """
}
