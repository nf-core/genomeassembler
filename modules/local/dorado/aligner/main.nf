process DORADO_ALIGNER {
    tag "${meta.id}"
    label 'process_high'

    container "docker.io/nanoporetech/dorado:sha00aa724a69ddc5f47d82bd413039f912fdaf4e77"

    input:
    tuple val(meta), path(ref), path(reads)

    output:
    tuple val(meta), path("${task.ext.prefix ?: meta.id}_dorado_aligned.bam"), emit: bam
    tuple val(meta), path("${task.ext.prefix ?: meta.id}_dorado_aligned.bam.bai"), emit: bai
    tuple val("${task.process}"), val('dorado'), eval('dorado --version 2>&1 | head -n1'), emit: versions_dorado, topic: versions
    tuple val("${task.process}"), val('samtools'), eval("samtools version | sed '1!d;s/.* //'"), topic: versions, emit: versions_samtools


    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''

    """
    dorado aligner \\
        -t ${task.cpus} \\
        ${ref} \\
        ${reads} \\
        ${args} \\
        | samtools sort --threads ${task.cpus}\\
        > ${task.ext.prefix ?: meta.id}_dorado_aligned.bam

    samtools index ${task.ext.prefix ?: meta.id}_dorado_aligned.bam > ${task.ext.prefix ?: meta.id}_dorado_aligned.bam.bai
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    touch ${prefix}_dorado_aligned.bam
    touch ${prefix}_dorado_aligned.bam.bai
    """
}
