process SAMTOOLS_GET_UNMAPPED {
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
    tuple val(meta), path(bam)

    output:
    tuple val(meta), path("*fastq.gz"), emit: unmapped_fq
    script:
    """
    samtools fastq -f 4 $bam \
    -1 ${bam}.unmapped_R1.fastq.gz \
    -2 ${bam}.unmapped_R2.fastq.gz
    """
}
