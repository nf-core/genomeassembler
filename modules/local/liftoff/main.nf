process LIFTOFF {
  tag "$meta"
  label 'process_high'
  

  publishDir(
    path: { "${params.out}/${task.process}".replace(':','/').toLowerCase() }, 
    mode: 'copy',
    overwrite: true,
    saveAs: { fn -> fn.substring(fn.lastIndexOf('/')+1) }
  ) 
  conda "bioconda::liftoff=1.6.4"
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