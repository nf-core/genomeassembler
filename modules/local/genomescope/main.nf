process GENOMESCOPE {
    tag "$meta.id"
    label 'process_medium'
    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/genomescope2:2.0--py311r42hdfd78af_6':
        'biocontainers/genomescope2:2.0--py311r42hdfd78af_6' }"

    input:
        tuple val(meta), path(histo), val(kmer_length), val(read_length)

    output:
        tuple val(meta), path("*_genomescope.txt"), emit: summary
        tuple val(meta), path("*_plot.log.png"), emit: plot_log
        tuple val(meta), path("*_plot.png"), emit: plot
        tuple val(meta), env(est_hap_len), emit: estimated_hap_len

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    genomescope.R $histo $kmer_length $read_length genomescope
    mv genomescope/summary.txt ${prefix}_genomescope.txt
    mv genomescope/plot.log.png ${prefix}_plot.log.png
    mv genomescope/plot.png ${prefix}_plot.png
    est_hap_len=\$(cat ${prefix}_genomescope.txt \\
        | grep 'Haploid Length' \\
        | sed 's@ bp@@g' \\
        | sed 's@,@@g' \\
        | awk '{printf "%i", (\$4+\$5)/2 }')
    """
    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}_genomescope.txt
    touch ${prefix}_plot.log.png
    touch ${prefix}_plot.png
    est_hap_len=1
    """
}
