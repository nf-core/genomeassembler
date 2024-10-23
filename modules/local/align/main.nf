process ALIGN {
    tag "$meta.id"
    label 'process_low'
    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/mulled-v2-66534bcbb7031a148b13e2ad42583020b9cd25c4:3161f532a5ea6f1dec9be5667c9efc2afdac6104-0' :
        'biocontainers/mulled-v2-66534bcbb7031a148b13e2ad42583020b9cd25c4:3161f532a5ea6f1dec9be5667c9efc2afdac6104-0' }"
    
    input:
        tuple val(meta), path(reads), path(reference)

    output:
        tuple val(meta), path("*.sam"), emit: alignment

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
        """
        minimap2 -t $task.cpus \\
            -ax map-ont ${reference} ${reads}  > ${prefix}.sam
        """
}

process ALIGN_TO_BAM {
    tag "$meta.id"
    label 'process_low'
    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/mulled-v2-66534bcbb7031a148b13e2ad42583020b9cd25c4:3161f532a5ea6f1dec9be5667c9efc2afdac6104-0' :
        'biocontainers/mulled-v2-66534bcbb7031a148b13e2ad42583020b9cd25c4:3161f532a5ea6f1dec9be5667c9efc2afdac6104-0' }"
    
    publishDir(
      path: { "${params.out}/${task.process}".replace(':','/').toLowerCase() }, 
      mode: 'copy',
      overwrite: true,
      saveAs: { fn -> fn.substring(fn.lastIndexOf('/')+1) }
    ) 

    input:
        tuple val(meta), path(reads), path(reference)

    output:
        tuple val(meta), path("*.bam"), emit: alignment

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
        """
        minimap2 -t $task.cpus \\
            -ax map-ont ${reference} ${reads} \\
            | samtools sort -o ${prefix}_${reference}.bam
        """
}

process ALIGN_SHORT_TO_BAM {
    tag "$meta"
    label 'process_low'
    conda "${moduleDir}/environment.yml"    
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/mulled-v2-66534bcbb7031a148b13e2ad42583020b9cd25c4:3161f532a5ea6f1dec9be5667c9efc2afdac6104-0' :
        'biocontainers/mulled-v2-66534bcbb7031a148b13e2ad42583020b9cd25c4:3161f532a5ea6f1dec9be5667c9efc2afdac6104-0' }"
    
    input:
        tuple val(meta), val(paired), path(reads), path(reference)

    output:
        tuple val(meta), path("*.bam"), emit: alignment

    script:
     def prefix = task.ext.prefix ?: "${meta.id}"
     def reads1 = [], reads2 = []
     paired ? [reads].flatten().each{reads1 << it} : reads.eachWithIndex{ v, ix -> ( ix & 1 ? reads2 : reads1) << v }
        """
        minimap2 -t $task.cpus \\
        -ax sr ${reference} ${reads1.join(",")} ${reads2.join(",")} \\
        | samtools sort -o ${prefix}_${reference}_shortreads.bam
        """
}