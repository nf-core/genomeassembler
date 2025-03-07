process COLLECT_READS {
    tag "${meta.id}"
    label 'process_low'

    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container
        ? 'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/52/52ccce28d2ab928ab862e25aae26314d69c8e38bd41ca9431c67ef05221348aa/data'
        : 'community.wave.seqera.io/library/coreutils_grep_gzip_lbzip2_pruned:838ba80435a629f8'}"

    input:
    tuple val(meta), path(read_directory)

    output:
    tuple val(meta), path("*.fastq"), emit: combined_reads
    path "versions.yml", emit: versions

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    gunzip -c ${read_directory}/*.gz > ${prefix}_all_reads.fastq
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gzip: \$(echo \$(gzip --version | head -n1 | sed 's/gzip //'))
    END_VERSIONS
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}_all_reads.fastq
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        gzip: \$(echo \$(gzip --version | head -n1 | sed 's/gzip //'))
    END_VERSIONS
    """
}
