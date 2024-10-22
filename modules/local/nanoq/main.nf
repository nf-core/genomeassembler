process NANOQ {
    tag "$meta.id"
    label 'process_low'
    conda "${moduleDir}/environment.yml"

    container "${workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/nanoq:0.10.0--h031d066_2' :
        'biocontainers/nanoq:0.10.0--h031d066_2'}"
    publishDir(
      path: { "${params.out}/${task.process}".replace(':','/').toLowerCase() }, 
      mode: 'copy',
      overwrite: true,
      saveAs: { fn -> fn.substring(fn.lastIndexOf('/')+1) }
    ) 
    input:
        tuple val(meta), path(reads)

    output:
        tuple val(meta), path("*_report.json"), emit: report
        tuple val(meta), path("*_stats.json"), emit: stats
        tuple val(meta), env(median), emit: median_length

    script:
        """
        nanoq -i ${reads} -j -r ${meta.id}_report.json -s -H -vvv > ${meta.id}_stats.json
        median=\$(cat ${meta.id}_report.json | grep -o '"median_length":[0-9]*' | grep -o '[0-9]*')
        """
}