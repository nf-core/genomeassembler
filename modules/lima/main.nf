process LIMA {
    tag "$meta"
    label 'process_medium'
    publishDir(
      path: { "${params.out}/${task.process}".replace(':','/').toLowerCase() }, 
      mode: 'copy',
      overwrite: true,
      saveAs: { fn -> fn.substring(fn.lastIndexOf('/')+1) }
    ) 
    input:
        tuple val(meta), path(reads)
        path(primers)

    output:
        tuple val(meta), path("*.report")           , emit: report
        tuple val(meta), path("*.counts")           , emit: counts
        tuple val(meta), path("*.summary")          , emit: summary
        tuple val(meta), path("*.bam")              , emit: bam
        tuple val(meta), path("*.bam.pbi")          , optional: true, emit: pbi
        tuple val(meta), path("*.xml")              , optional: true, emit: xml
        tuple val(meta), path("*.json")             , optional: true, emit: json
        tuple val(meta), path("*.clips")            , optional: true, emit: clips
        tuple val(meta), path("*.guess")            , optional: true, emit: guess
    
    script: 
    def args = task.ext.args ?: ''
    if( "$reads" == "${meta}.bam" ) error "Input and output names are the same"

    """
    lima \\ 
        --isoseq \\
        ${reads} \\
        $primers \\
        ${meta}.bam \\
        -j $task.cpus \\
        $args
    """

}

process REFINE {
    tag "$meta"
    label 'process_low'

    input:
    tuple val(meta), path(bam)
    path primers
    val(pacbio_polya)

    output:
    tuple val(meta), path("*_refined.bam")               , emit: bam
    tuple val(meta), path("*.bam.pbi")                   , emit: pbi
    tuple val(meta), path("*.consensusreadset.xml")      , emit: consensusreadset
    tuple val(meta), path("*.filter_summary.report.json"), emit: summary
    tuple val(meta), path("*.report.csv")                , emit: report

    script:
    def args = task.ext.args ?: ''
    def poly_a = pacbio_polya ? '--require-polya' : ''
    """
    isoseq \\
        refine \\
        $poly_a \\
        -j $task.cpus \\
        $args \\
        $bam \\
        $primers \\
        ${meta}_refined.bam
    """
}
