include { initOptions; saveFiles; getSoftwareName } from './functions'

params.options = [:]
options        = initOptions(params.options)

process LINKS {
  tag "$meta"
  label 'process_high'
  
  container "quay.io/biocontainers/links:2.0.1--h9f5acd7_3"

  publishDir "${params.out}",
      mode: params.publish_dir_mode,
      saveAs: { filename -> saveFiles(filename:filename,
                                      options:params.options, 
                                      publish_dir:"${task.process}".replace(':','/').toLowerCase(), 
                                      publish_id:meta) }
  input:
      tuple val(meta), path(assembly), path(reads)

  output:
      tuple val(meta), path("*.scaffolds.fa"), emit: scaffolds
      tuple val(meta), path("*.scaffolds"), emit: scaffold_csv
      tuple val(meta), path("*.gv"), emit: graph
      tuple val(meta), path("*.log"), emit: log
  
  script:
      def prefix = task.ext.prefix ?: "${meta}"
  """
  echo "${reads}" > readfile.fof
  LINKS -f ${assembly} -s readfile.fof -j 3 -b ${meta}_links -t 40,200 -d 500,2000,5000
  sed -i 's/\\(scaffold[0-9]*\\).*/\\1/' ${meta}_links.scaffolds.fa
  """
}