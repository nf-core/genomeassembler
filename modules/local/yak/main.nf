process KMER_ASSEMBLY {
    tag "$meta.id"
    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/yak:0.1--he4a0461_4':
        'biocontainers/yak:0.1--he4a0461_4' }"

    input:
    tuple val(meta), path(assembly)

    output:
    tuple val(meta), path("${assembly}.yak")       , emit: assembly_hashes

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    yak count -K1.5g -t$task.cpus -o ${assembly}.yak ${assembly}
    """
}

process KMER_LONGREADS {
    tag "$meta.id"
    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/yak:0.1--he4a0461_4':
        'biocontainers/yak:0.1--he4a0461_4' }"

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("*.yak")       , emit: read_hashes

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    yak count -b37 -t$task.cpus -o ${reads}.yak $reads
    """
}

process KMER_SHORTREADS {
    tag "$meta.id"
    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/yak:0.1--he4a0461_4':
        'biocontainers/yak:0.1--he4a0461_4' }"

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("*.yak")       , emit: read_hashes

    when:
    task.ext.when == null || task.ext.when

    script:
    def input_reads = meta.paired ? "<(zcat ${reads}) <(zcat ${reads})" : "${reads}"
    def prefix = meta.id
    """
    yak count -b37 -t$task.cpus -o ${prefix}_shortreads.yak $input_reads
    """
}

process READ_QV {
    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/yak:0.1--he4a0461_4':
        'biocontainers/yak:0.1--he4a0461_4' }"
    tag "$meta.id"

    input:
      tuple val(meta), path(longread_yak), path(shortread_yak)

    output:
      tuple val(meta), path("*.kqv.txt"), emit: read_qv

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = ${meta.id}
    """
    name=(basename $longread_yak yak)
    yak inspect $longread_yak $shortread_yak > ${prefix}.\$name.longread_shortread.kqv.txt
    """
}
process ASSEMBLY_KQV {
    tag "$meta.id"
    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/yak:0.1--he4a0461_4':
        'biocontainers/yak:0.1--he4a0461_4' }"

    input:
    tuple val(meta), path(assembly_yak), path(shortread_yak)

    output:
    tuple val(meta), path("*.kqv.txt")       , emit: kqv

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = ${meta.id}

    """
    yak inspect $shortread_yak $assembly_yak > ${prefix}.assembly_shortread.kqv.txt
    """
}

process KMER_HISTOGRAM {
    tag "$meta.id"
    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/yak:0.1--he4a0461_4':
        'biocontainers/yak:0.1--he4a0461_4' }"

    input:
    tuple val(meta), path(yakfile)

    output:
    tuple val(meta), path("*.hist")       , emit: kmer_histo

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    yak inspect $yakfile > ${yakfile}.hist
    """
}
