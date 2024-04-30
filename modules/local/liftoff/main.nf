include { initOptions; saveFiles; getSoftwareName } from './functions'

params.options = [:]
options        = initOptions(params.options)

process LIFTOFF {
  tag "$meta"
  label 'process_high'
  
  conda "bioconda::liftoff=1.6.4"
  container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
          'https://depot.galaxyproject.org/singularity/liftoff:1.6.3--pyhdfd78af_0' :
          'quay.io/biocontainers/liftoff:1.6.3--pyhdfd78af_0' }"

  publishDir "${params.out}",
    mode: params.publish_dir_mode,
    saveAs: { filename -> saveFiles(filename:filename,
                                    options:params.options, 
                                    publish_dir:"${task.process}".replace(':','/').toLowerCase(), 
                                    publish_id:meta) }
  input:
      tuple val(meta), path(assembly), path(reference_fasta), path(reference_gff)
  
  output:
      tuple val(meta), path("*_liftoff.gff"), emit: lifted_annotations

  
  script:
      def prefix = task.ext.prefix ?: "${meta}"
  """
  if [[ ${assembly} == *.gz ]]; then
    zcat ${assembly} > assembly.fasta
  fi

  if [[ ${assembly} == *.fa || ${assembly} == *.fasta ]]; then
    cp ${assembly} assembly.fasta
  fi

  liftoff \\
    -g ${reference_gff} \\
    -p ${task.cpus} \\
    assembly.fasta  \\
    ${reference_fasta} \\
    -o ${assembly.baseName}_liftoff.gff
  """
}