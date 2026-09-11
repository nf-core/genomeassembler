process COLLECT_READS {
    tag "${meta.id}"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container
        ? 'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/52/52ccce28d2ab928ab862e25aae26314d69c8e38bd41ca9431c67ef05221348aa/data'
        : 'community.wave.seqera.io/library/coreutils_grep_gzip_lbzip2_pruned:838ba80435a629f8'}"

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("*_all_reads.fq.gz"), emit: combined_reads
    tuple val("${task.process}"), val('gzip'), eval('gzip --version | head -n1 | sed "s/gzip //"'), emit: versions_collect_reads, topic: versions

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    cat ${reads} > ${prefix}_all_reads.fq.gz
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}_all_reads.fq; gzip ${prefix}_all_reads.fq
    """
}
