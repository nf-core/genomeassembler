process QUAST {
    tag "$meta"
    label 'process_medium'
    conda "bioconda::quast=5.2.0"
    publishDir(
      path: { "${params.out}/${task.process}".replace(':','/').toLowerCase() }, 
      mode: 'copy',
      overwrite: true,
      saveAs: { fn -> fn.substring(fn.lastIndexOf('/')+1) }
    ) 
    input:
    tuple val(meta), path(consensus), path(fasta), path(gff), path(ref_bam), path(bam)
    val use_fasta
    val use_gff

    output:
    path "${meta}"      , emit: results
    path "${meta}/*.tsv", emit: tsv
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
        --output-dir $meta \\
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

    ln -s ${prefix}/report.tsv

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        quast: \$(quast.py --version 2>&1 | sed 's/^.*QUAST v//; s/ .*\$//')
    END_VERSIONS
    """
}
