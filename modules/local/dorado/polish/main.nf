process DORADO_POLISH {
    tag "${meta.id}"
    label 'process_high'

    container "docker.io/nanoporetech/dorado:sha00aa724a69ddc5f47d82bd413039f912fdaf4e77"

    input:
    tuple val(meta), path(assembly), path(alignment), path(index)
    val(variant_call_format)

    output:
    tuple val(meta), path("${meta.id}_dorado_polished.fa.gz"), emit: polished_alignment, optional: true
    tuple val(meta), path("${meta.id}_dorado_polished*vcf"), emit: variant_calls, optional: true
    tuple val("${task.process}"), val('dorado'), eval('dorado --version 2>&1 | head -n1'), emit: versions_dorado, topic: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def variants = ["vcf","gvcf"].contains(variant_call_format) ? "--${variant_call_format}" : ""
    def outfile = variants ? "> ${meta.id}_dorado_polished.${variants}" : "| bgzip > ${meta.id}_dorado_polished.fa.gz"
    """
    dorado polish \\
        -t ${task.cpus} \\
        ${alignment} \\
        ${assembly} \\
        ${args} \\
        ${variants} \\
        ${outfile}
    """

    stub:
    def args   = task.ext.args ?: ''
    def variants = ["vcf","gvcf"].contains(variant_call_format) ? "--${variant_call_format}" : ""
    def outfile = variants ? "touch ${meta.id}_dorado_polished.${variants}" : "echo '' | bgzip > ${meta.id}_dorado_polished.fa.gz"
    """
    ${outfile}
    """
}
