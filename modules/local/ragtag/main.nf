process RAGTAG_SCAFFOLD {
  tag "$meta"
  label 'process_high'
  conda "bioconda::ragtag=2.1.0"
  publishDir(
    path: { "${params.out}/${task.process}".replace(':','/').toLowerCase() }, 
    mode: 'copy',
    overwrite: true,
    saveAs: { fn -> fn.substring(fn.lastIndexOf('/')+1) }
  ) 
  
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