include { initOptions; saveFiles; getSoftwareName } from './functions'

params.options = [:]
options        = initOptions(params.options)

process ALIGN {
    tag "$meta"
    label 'process_low'
    publishDir "${params.out}",
        mode: params.publish_dir_mode,
        saveAs: { filename -> saveFiles(filename:filename,
                                        options:params.options, 
                                        publish_dir:"${task.process}".replace(':','/').toLowerCase(), 
                                        publish_id:meta) }
    input:
        tuple val(meta), path(reads), path(reference)

    output:
        tuple val(meta), path("*.sam"), emit: alignment

    script:
        """
        minimap2 -t $task.cpus \\
            -ax map-ont ${reference} ${reads}  > ${meta}.sam
        """
}

process ALIGN_TO_BAM {
    tag "$meta"
    label 'process_low'
    publishDir "${params.out}",
        mode: params.publish_dir_mode,
        saveAs: { filename -> saveFiles(filename:filename,
                                        options:params.options, 
                                        publish_dir:"${task.process}".replace(':','/').toLowerCase(), 
                                        publish_id:meta) }
    input:
        tuple val(meta), path(reads), path(reference)

    output:
        tuple val(meta), path("*.bam"), emit: alignment

    script:
        """
        minimap2 -t $task.cpus \\
            -ax map-ont ${reference} ${reads} \\
            | samtools sort -o ${meta}_${reference}.bam
        """
}

process ALIGN_SHORT_TO_BAM {
    tag "$meta"
    label 'process_low'
    publishDir "${params.out}",
        mode: params.publish_dir_mode,
        saveAs: { filename -> saveFiles(filename:filename,
                                        options:params.options, 
                                        publish_dir:"${task.process}".replace(':','/').toLowerCase(), 
                                        publish_id:meta) }

    input:
        tuple val(meta), val(paired), path(reads), path(reference)

    output:
        tuple val(meta), path("*.bam"), emit: alignment

    script:
     def reads1 = [], reads2 = []
     paired ? [reads].flatten().each{reads1 << it} : reads.eachWithIndex{ v, ix -> ( ix & 1 ? reads2 : reads1) << v }
        """
        minimap2 -t $task.cpus \\
        -ax sr ${reference} ${reads1.join(",")} ${reads2.join(",")} \\
        | samtools sort -o ${meta}_${reference}_shortreads.bam
        """
}