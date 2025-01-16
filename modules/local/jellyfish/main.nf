process COUNT {
    tag "$meta.id"
    label 'process_medium'
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/mer-jellyfish:2.3.1--h4ac6f70_0' :
        'biocontainers/kmer-jellyfish:2.3.1--h4ac6f70_0' }"

    input:
        tuple val(meta), path(fasta)

    output:
        tuple val(meta), path("*.jf"), emit: kmers

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
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
         
        mv mer_counts.jf ${prefix}_mer_counts.jf
        """
}

process HISTO {
    tag "$meta.id"
    label 'process_medium'
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/mer-jellyfish:2.3.1--h4ac6f70_0' :
        'biocontainers/kmer-jellyfish:2.3.1--h4ac6f70_0' }"

    input:
        tuple val(meta), path(kmers)

    output:
        tuple val(meta), path("*.tsv"), emit: histo

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
        """
        jellyfish histo $kmers > ${prefix}_hist.tsv         
        """
}

process STATS {
    tag "$meta.id"
    label 'process_medium'
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/mer-jellyfish:2.3.1--h4ac6f70_0' :
        'biocontainers/kmer-jellyfish:2.3.1--h4ac6f70_0' }"
    input:
        tuple val(meta), path(kmers)

    output:
        tuple val(meta), path("*.txt"), emit: stats

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
        """
        jellyfish stats $kmers > ${prefix}_stats.txt       
        """
}

process DUMP {
    tag "$meta.id"
    label 'process_medium'
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/mer-jellyfish:2.3.1--h4ac6f70_0' :
        'biocontainers/kmer-jellyfish:2.3.1--h4ac6f70_0' }"
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
    def prefix = task.ext.prefix ?: "${meta.id}"
        """
        jellyfish dump $kmers > ${prefix}_kmers.fa  
        """
}