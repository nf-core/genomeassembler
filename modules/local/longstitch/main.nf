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
    path "versions.yml", emit: versions

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

    mv *.tigmint-ntLink-arks.longstitch-scaffolds.fa ${prefix}.tigmint-ntLink-arks.longstitch-scaffolds.fa
    sed -i 's/\\(scaffold[0-9]*\\),.*/\\1/' ${prefix}.tigmint-ntLink-arks.longstitch-scaffolds.fa


    mv  *.tigmint-ntLink.longstitch-scaffolds.fa  ${prefix}.tigmint-ntLink.longstitch-scaffolds.fa
    sed -i 's/\\(scaffold[0-9]*\\),.*/\\1/' ${prefix}.tigmint-ntLink.longstitch-scaffolds.fa

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        LINKS: \$(echo \$(longstitch | head -n1 | sed 's/LongStitch v//'))
    END_VERSIONS
    """
    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.tigmint-ntLink-arks.longstitch-scaffolds.fa
    touch ${prefix}.tigmint-ntLink.longstitch-scaffolds.fa
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        LINKS: \$(echo \$(longstitch | head -n1 | sed 's/LongStitch v//'))
    END_VERSIONS
    """
}
