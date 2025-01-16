process ALIGN {
    tag "${meta.id}"
    label 'process_medium'
    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container
        ? 'https://depot.galaxyproject.org/singularity/mulled-v2-66534bcbb7031a148b13e2ad42583020b9cd25c4:3161f532a5ea6f1dec9be5667c9efc2afdac6104-0'
        : 'biocontainers/mulled-v2-66534bcbb7031a148b13e2ad42583020b9cd25c4:3161f532a5ea6f1dec9be5667c9efc2afdac6104-0'}"

    input:
    tuple val(meta), path(reads), path(reference)

    output:
    tuple val(meta), path("*.sam"), emit: alignment

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    def map_mode = (params.ont & !params.hifi) | (params.ont && params.hifi && params.qc_reads == "ONT")
        ? 'map-ont'
        : (!params.ont && params.hifi) | (params.ont && params.hifi && params.qc_reads == "HIFI") ? 'map-hifi' : 'map-ont'
    """
    minimap2 -t ${task.cpus} \\
        -ax ${map_mode} \\
        ${reference} ${reads}  > ${prefix}.sam
    """
}

process ALIGN_TO_BAM {
    tag "${meta.id}"
    label 'process_medium'
    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container
        ? 'https://depot.galaxyproject.org/singularity/mulled-v2-66534bcbb7031a148b13e2ad42583020b9cd25c4:3161f532a5ea6f1dec9be5667c9efc2afdac6104-0'
        : 'biocontainers/mulled-v2-66534bcbb7031a148b13e2ad42583020b9cd25c4:3161f532a5ea6f1dec9be5667c9efc2afdac6104-0'}"

    input:
    tuple val(meta), path(reads), path(reference)

    output:
    tuple val(meta), path("*.bam"), emit: alignment

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    def map_mode = (params.ont & !params.hifi) | (params.ont && params.hifi && params.qc_reads == "ONT")
        ? 'map-ont'
        : (!params.ont && params.hifi) | (params.ont && params.hifi && params.qc_reads == "HIFI") ? 'map-hifi' : 'map-ont'
    """
    minimap2 -t ${task.cpus} \\
        -ax ${map_mode} ${reference} ${reads} \\
    | samtools sort -o ${prefix}_${reference}.bam
    """
}

process ALIGN_SHORT_TO_BAM {
    tag "${meta.id}"
    label 'process_medium'
    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container
        ? 'https://depot.galaxyproject.org/singularity/mulled-v2-66534bcbb7031a148b13e2ad42583020b9cd25c4:3161f532a5ea6f1dec9be5667c9efc2afdac6104-0'
        : 'biocontainers/mulled-v2-66534bcbb7031a148b13e2ad42583020b9cd25c4:3161f532a5ea6f1dec9be5667c9efc2afdac6104-0'}"

    input:
    tuple val(meta), val(paired), path(in_reads), path(reference)

    output:
    tuple val(meta), path("*.bam"), emit: alignment

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    def reads = paired ? "${in_reads[0]} ${in_reads[1]}" : "${in_reads[0]}"
    """
    minimap2 -t ${task.cpus} \\
        -ax sr ${reference} ${reads} \\
    | samtools sort -o ${prefix}_${reference}_shortreads.bam
    """
}
