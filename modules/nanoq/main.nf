process NANOQ {
    tag "$meta"
    label 'process_low'
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
        nanoq -i ${reads} -j -r ${meta}_report.json -s -H -vvv > ${meta}_stats.json
        median=\$(cat ${meta}_report.json | grep -o '"median_length":[0-9]*' | grep -o '[0-9]*')
        """
}