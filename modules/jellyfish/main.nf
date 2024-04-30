include { initOptions; saveFiles; getSoftwareName } from './functions'

params.options = [:]
options        = initOptions(params.options)

process COUNT {
    tag "$meta"
    label 'process_medium'
    publishDir "${params.out}",
        mode: params.publish_dir_mode,
        saveAs: { filename -> saveFiles(filename:filename,
                                        options:params.options, 
                                        publish_dir:"${task.process}".replace(':','/').toLowerCase(), 
                                        publish_id:meta) }
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
    publishDir "${params.out}",
        mode: params.publish_dir_mode,
        saveAs: { filename -> saveFiles(filename:filename,
                                        options:params.options, 
                                        publish_dir:"${task.process}".replace(':','/').toLowerCase(), 
                                        publish_id:meta) }
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
    publishDir "${params.out}",
        mode: params.publish_dir_mode,
        saveAs: { filename -> saveFiles(filename:filename,
                                        options:params.options, 
                                        publish_dir:"${task.process}".replace(':','/').toLowerCase(), 
                                        publish_id:meta) }
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
    publishDir "${params.out}",
        mode: params.publish_dir_mode,
        saveAs: { filename -> saveFiles(filename:filename,
                                        options:params.options, 
                                        publish_dir:"${task.process}".replace(':','/').toLowerCase(), 
                                        publish_id:meta) }
    input:
        tuple val(meta), path(kmers)

    output:
        tuple val(meta), path("*.fa"), emit: dumped_kmers

    script:
        """
        jellyfish dump $kmers > ${meta}_kmers.fa  
        """
}