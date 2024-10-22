process QUAST {
    tag "$meta.id"
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/quast:5.2.0--py39pl5321h2add14b_1' :
        'biocontainers/quast:5.2.0--py39pl5321h2add14b_1' }"

    input:
    tuple val(meta), path(consensus), path(fasta), path(gff), path(ref_bam), path(bam)
    val use_fasta
    val use_gff

    output:
    path "${meta.id}"      , emit: results
    path "${meta.id}/*.tsv", emit: tsv
    path "versions.yml" , emit: versions
    

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args   ?: ''
    prefix   = task.ext.prefix ?: 'quast'
    def features  = use_gff ? "--features $gff" : ''
    def reference = use_fasta ? "-r $fasta" : ''
    def reference_bam = params.use_ref ? "--ref-bam ${ref_bam}" : ''

    """
    quast.py \\
        --output-dir ${meta.id} \\
        $reference \\
        $features \\
        --threads $task.cpus \\
        ${consensus.join(' ')} \\
        --glimmer \\
        --conserved-genes-finding \\
        $reference_bam \\
        --bam ${bam} \\
        --large \\
        ${args}

    ln -s ${meta.id}/report.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        quast: \$(quast.py --version 2>&1 | sed 's/^.*QUAST v//; s/ .*\$//')
    END_VERSIONS
    """
}