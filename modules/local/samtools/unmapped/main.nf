process SAMTOOLS_GET_UNMAPPED {
    tag "$meta.id"
    label 'process_low'
    conda "bioconda::samtools=1.10"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/ragtag:1.15.1--h1170115_0':
        'biocontainers/samtools:1.15.1--h1170115_0' }"

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
