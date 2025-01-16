process RAGTAG_SCAFFOLD {
  tag "$meta.id"
  label 'process_high'
  conda "${moduleDir}/environment.yml"
  container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/ragtag:2.1.0--pyhb7b1952_0':
        'biocontainers/ragtag:2.1.0--pyhb7b1952_0' }"
  
  input:
      tuple val(meta), path(assembly), path(reference)
  
  output:
      tuple val(meta), path("${assembly}_ragtag_${reference}/*.fasta"), emit: corrected_assembly
      tuple val(meta), path("${assembly}_ragtag_${reference}/*.agp"),   emit: corrected_agp
      tuple val(meta), path("${assembly}_ragtag_${reference}/*.stats"), emit: corrected_stats
  
  script:
      def prefix = task.ext.prefix ?: "${meta.id}"
  """
  if [[ ${assembly} == *.gz ]]
    then 
      zcat ${assembly} > ${prefix}.fa
    else
      mv ${assembly} ${prefix}.fa
  fi
  
  ragtag.py scaffold ${reference} ${prefix}.fa \\
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