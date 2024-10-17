process SAMTOOLS_FASTQ {
    tag "$meta"
    label 'process_low'
    publishDir(
      path: { "${params.out}/${task.process}".replace(':','/').toLowerCase() }, 
      mode: 'copy',
      overwrite: true,
      saveAs: { fn -> fn.substring(fn.lastIndexOf('/')+1) }
    ) 
    conda "bioconda::samtools=1.10"

    input:
    tuple val(meta), path(bam), path(bai)

    output:
    tuple val(meta), path("*.fq.gz"), emit: fasta

    script:
    """
    samtools fastq $bam | gzip | ${meta}.fq.gz
    """
}
