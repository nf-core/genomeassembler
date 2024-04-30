include { initOptions; saveFiles; getSoftwareName } from './functions'

params.options = [:]
options        = initOptions(params.options)

process RAGTAG_SCAFFOLD {
  tag "$meta"
  label 'process_high'
  
  conda "bioconda::ragtag=2.1.0"
  container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
          'https://depot.galaxyproject.org/singularity/ragtag:2.1.0--pyhb7b1952_0' :
          'quay.io/biocontainers/ragtag:2.1.0--pyhb7b1952_0' }"

  publishDir "${params.out}",
      mode: params.publish_dir_mode,
      saveAs: { filename -> saveFiles(filename:filename,
                                      options:params.options, 
                                      publish_dir:"${task.process}".replace(':','/').toLowerCase(), 
                                      publish_id:meta) }
  input:
      tuple val(meta), path(assembly), path(reference)
  
  output:
      tuple val(meta), path("${assembly}_ragtag_${reference}/*.fasta"), emit: corrected_assembly
      tuple val(meta), path("${assembly}_ragtag_${reference}/*.agp"),   emit: corrected_agp
      tuple val(meta), path("${assembly}_ragtag_${reference}/*.stats"), emit: corrected_stats
  
  script:
      def prefix = task.ext.prefix ?: "${meta}"
  """
  zcat ${assembly} > ${meta}.fa
  ragtag.py scaffold ${reference} ${meta}.fa \\
    -o "${assembly}_ragtag_${reference}" \\
    -t $task.cpus \\
    -f 5000 \\
    -w \\
    -C \\
    -u \\
    -r 

  mv ${assembly}_ragtag_${reference}/ragtag.scaffold.fasta ${assembly}_ragtag_${reference}/${assembly}_ragtag_${reference}.fasta
  mv ${assembly}_ragtag_${reference}/ragtag.scaffold.agp ${assembly}_ragtag_${reference}/${assembly}_ragtag_${reference}.agp
  mv ${assembly}_ragtag_${reference}/ragtag.scaffold.stats ${assembly}_ragtag_${reference}/${assembly}_ragtag_${reference}.stats
  """
}