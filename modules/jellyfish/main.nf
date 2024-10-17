process COUNT {
    tag "$meta"
    label 'process_medium'
    publishDir(
      path: { "${params.out}/${task.process}".replace(':','/').toLowerCase() }, 
      mode: 'copy',
      overwrite: true,
      saveAs: { fn -> fn.substring(fn.lastIndexOf('/')+1) }
    ) 
    input:
        tuple val(meta), path(fasta)

    output:
        tuple val(meta), path("*.jf"), emit: kmers

    script:
        """
        if [[ ${fasta} == *.gz ]]; then
            zcat ${fasta} > ${fasta.baseName}.fasta
        fi
        if [[ ${fasta} == *.fa ]]; then
            cp ${fasta} ${fasta.baseName}.fasta 
        fi
        if [[ ${fasta} == *.fastq ]]; then
            cp ${fasta} ${fasta.baseName}.fasta 
        fi
        jellyfish count \\
         -m ${params.kmer_length} \\
         -s 140M \\
         -C \\
         -t $task.cpus ${fasta.baseName}.fasta 
         
        mv mer_counts.jf ${meta}_mer_counts.jf
        """
}

process HISTO {
    tag "$meta"
    label 'process_medium'
    publishDir(
      path: { "${params.out}/${task.process}".replace(':','/').toLowerCase() }, 
      mode: 'copy',
      overwrite: true,
      saveAs: { fn -> fn.substring(fn.lastIndexOf('/')+1) }
    ) 
    input:
        tuple val(meta), path(kmers)

    output:
        tuple val(meta), path("*.tsv"), emit: histo

    script:
        """
        jellyfish histo $kmers > ${meta}_hist.tsv         
        """
}

process STATS {
    tag "$meta"
    label 'process_medium'

    publishDir(
      path: { "${params.out}/${task.process}".replace(':','/').toLowerCase() }, 
      mode: 'copy',
      overwrite: true,
      saveAs: { fn -> fn.substring(fn.lastIndexOf('/')+1) }
    ) 
    input:
        tuple val(meta), path(kmers)

    output:
        tuple val(meta), path("*.txt"), emit: stats

    script:
        """
        jellyfish stats $kmers > ${meta}_stats.txt       
        """
}

process DUMP {
    tag "$meta"
    label 'process_medium'
    publishDir(
      path: { "${params.out}/${task.process}".replace(':','/').toLowerCase() }, 
      mode: 'copy',
      overwrite: true,
      saveAs: { fn -> fn.substring(fn.lastIndexOf('/')+1) }
    ) 
    input:
        tuple val(meta), path(kmers)

    output:
        tuple val(meta), path("*.fa"), emit: dumped_kmers

    script:
        """
        jellyfish dump $kmers > ${meta}_kmers.fa  
        """
}