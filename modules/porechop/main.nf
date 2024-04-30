include { initOptions; saveFiles; getSoftwareName } from './functions'

params.options = [:]
options        = initOptions(params.options)

process PORECHOP {
    tag "$meta"
    label 'process_medium'

    publishDir "${params.out}",
        mode: params.publish_dir_mode,
        saveAs: { filename -> saveFiles(filename:filename,
                                        options:params.options, 
                                        publish_dir:"${task.process}".replace(':','/').toLowerCase(), 
                                        publish_id:meta) }
    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("*_porechopped.fastq.gz"), emit: reads
    tuple val(meta), path("*.log")     , emit: log
    path "versions.yml"                , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta}"
    """
    ## To ensure ID matches rest of pipeline based on id rather than input file name
    
    [[ -f ${prefix}.fastq.gz   ]] || ln -s $reads ${prefix}.fastq.gz

    micromamba run -n base porechop \\
        -i ${prefix}.fastq.gz \\
        -t $task.cpus \\
        $args \\
        -o ${prefix}_porechopped.fastq.gz \\
        > ${prefix}.log

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        porechop: \$( porechop --version )
    END_VERSIONS
    """
}