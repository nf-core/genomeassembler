include { initOptions; saveFiles; getSoftwareName } from './functions'

params.options = [:]
options        = initOptions(params.options)

process COLLECT_READS {
  tag "$meta"
  label 'process_low'
  publishDir "${params.out}",
        mode: params.publish_dir_mode,
        saveAs: { filename -> saveFiles(filename:filename,
                                        options:params.options, 
                                        publish_dir:"${task.process}".replace(':','/').toLowerCase(), 
                                        publish_id:meta) }
  conda "conda-forge::python=3.8.3"
  container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
          'https://depot.galaxyproject.org/singularity/python:3.8.3' :
          'quay.io/biocontainers/python:3.8.3' }"
  
  input:
      tuple val(meta), path(read_directory)
  
  output:
      tuple val(meta), path("*.fastq"), emit: combined_reads
  
  script:
      def prefix = task.ext.prefix ?: "${meta}"
      
  """
  gunzip -c ${read_directory}/*.gz > ${prefix}_all_reads.fastq
  """
}