process HIFIASM {
    tag "$meta.id"
    label 'process_high'
    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/hifiasm:0.19.9--h43eeafb_0' :
        'biocontainers/hifiasm:0.19.9--h43eeafb_0' }"

    input:
    tuple val(meta), path(reads)
    val(hifi_args)

    output:
    tuple val(meta), path("*.r_utg.gfa")       , emit: raw_unitigs
    tuple val(meta), path("*.p_utg.gfa")       , emit: processed_unitigs        , optional: true
    tuple val(meta), path("*.p_ctg.gfa")       , emit: primary_contigs          , optional: true
    tuple val(meta), path("*.p_ctg.fa.gz")     , emit: primary_contigs_fasta    , optional: true
    tuple val(meta), path("*.log")             , emit: log

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = hifi_args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    hifiasm \\
        $args \\
        -l0 \\
        -o ${prefix}.asm \\
        -t $task.cpus \\
        $reads \\
        2> >( tee ${prefix}.stderr.log >&2  )
    
    awk '/^S/{print ">"\$2;print \$3}' ${prefix}.asm.bp.p_ctg.gfa | gzip > ${prefix}.asm.bp.p_ctg.fa.gz
    """
    }

process HIFIASM_UL {
    tag "$meta.id"
    label 'process_high'
    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/hifiasm:0.19.9--h43eeafb_0' :
        'biocontainers/hifiasm:0.19.9--h43eeafb_0' }"

    input:
    tuple val(meta), path(hifi_reads), path(ont_reads)
    val(hifi_args)

    output:
    tuple val(meta), path("*.r_utg.gfa")       , emit: raw_unitigs
    tuple val(meta), path("*.p_utg.gfa")       , emit: processed_unitigs        , optional: true
    tuple val(meta), path("*.p_ctg.gfa")       , emit: primary_contigs          , optional: true
    tuple val(meta), path("*.p_ctg.fa.gz")     , emit: primary_contigs_fasta    , optional: true
    tuple val(meta), path("*.log")             , emit: log


    when:
    task.ext.when == null || task.ext.when

    script:
    def args = hifi_args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    hifiasm \\
        $args \\
        -l0 \\
        -o ${prefix}.asm \\
        -t $task.cpus \\
        --ul ${ont_reads} \\
        $hifi_reads \\
        2> >( tee ${meta.id}.stderr.log >&2  )
    
    awk '/^S/{print ">"\$2;print \$3}' ${prefix}.asm.bp.p_ctg.gfa | gzip > ${prefix}.asm.bp.p_ctg.fa.gz
    """
    }
