process LONGSTITCH {
    tag "${meta.id}"
    label 'process_high'
    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container
        ? 'https://depot.galaxyproject.org/singularity/longstitch:1.0.5--hdfd78af_0'
        : 'biocontainers/longstitch:1.0.5--hdfd78af_0'}"

    input:
    tuple val(meta), path(assembly), path(reads)

    output:
    tuple val(meta), path("*.tigmint-ntLink-arks.longstitch-scaffolds.fa"), emit: ntlLinks_arks_scaffolds
    tuple val(meta), path("*.tigmint-ntLink.longstitch-scaffolds.fa"), emit: ntlLinks_scaffolds

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    if [[ ${assembly} == *.gz ]]; then
        zcat ${assembly} | fold -w 120 > assembly.fasta
    fi

    if [[ ${assembly} == *.fa || ${assembly} == *.fasta ]]; then
        cat ${assembly}| fold -w 120 > assembly.fasta
    fi
    ln -s assembly.fasta assembly.fa

    if [[ ${reads} == *.fa || ${reads} == *.fasta || ${reads} == *.fq || ${reads} == *.fastq ]]; then
        gzip -c ${reads} > ${reads}.gz
        ln -s ${reads}.gz reads.fq.gz
    fi

    if [[ ${reads} == *.gz ]]; then
        cp ${reads} reads.fq.gz
    fi

    longstitch tigmint-ntLink-arks draft=assembly reads=reads t=${task.cpus} G=135e6 out_prefix=${prefix}
    cat *.tigmint-ntLink-arks.longstitch-scaffolds.fa | sed 's/\\(scaffold[0-9]*\\),.*/\\1/' > ${prefix}.tigmint-ntLink-arks.longstitch-scaffolds.fa
    cat *.tigmint-ntLink.longstitch-scaffolds.fa | sed 's/\\(scaffold[0-9]*\\),.*/\\1/' > ${prefix}.tigmint-ntLink.longstitch-scaffolds.fa
    """
    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.tigmint-ntLink-arks.longstitch-scaffolds.fa
    touch ${prefix}.tigmint-ntLink.longstitch-scaffolds.fa
    """
}
