include { initOptions; saveFiles; getSoftwareName } from './functions'

params.options = [:]
options        = initOptions(params.options)

process NANOQ {
    tag "$meta"
    label 'process_low'
    publishDir "${params.out}",
        mode: params.publish_dir_mode,
        saveAs: { filename -> saveFiles(filename:filename,
                                        options:params.options, 
                                        publish_dir:"${task.process}".replace(':','/').toLowerCase(), 
                                        publish_id:meta) }
    input:
        tuple val(meta), path(reads)

    output:
        tuple val(meta), path("*_report.json"), emit: report
        tuple val(meta), path("*_stats.json"), emit: stats
        tuple val(meta), env(median), emit: median_length

    script:
        """
        nanoq -i ${reads} -j -r ${meta}_report.json -s -H -vvv > ${meta}_stats.json
        median=\$(cat ${meta}_report.json | grep -o '"median_length":[0-9]*' | grep -o [0-9]*)
        """
}