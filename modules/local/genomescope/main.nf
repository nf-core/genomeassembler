process GENOMESCOPE {
    tag "$meta"
    label 'process_medium'
    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/r-base:4.4.1':
        'biocontainers/r-base:4.4.1' }"
    publishDir(
      path: { "${params.out}/${task.process}".replace(':','/').toLowerCase() }, 
      mode: 'copy',
      overwrite: true,
      saveAs: { fn -> fn.substring(fn.lastIndexOf('/')+1) }
    ) 
    input:
        tuple val(meta), path(histo), val(kmer_length), val(read_length)

    output:
        tuple val(meta), path("*_genomescope.txt"), emit: summary
        tuple val(meta), path("*_plot.log.png"), emit: plot_log
        tuple val(meta), path("*_plot.png"), emit: plot
        tuple val(meta), env(est_hap_len), emit: estimated_hap_len

    script:
        """
        genomescope.R $histo $kmer_length $read_length genomescope
        mv genomescope/summary.txt ${meta}_genomescope.txt
        mv genomescope/plot.log.png ${meta}_plot.log.png
        mv genomescope/plot.png ${meta}_plot.png
        est_hap_len=\$(cat ${meta}_genomescope.txt \\
            | grep 'Haploid Length' \\
            | sed 's@ bp@@g' \\
            | sed 's@,@@g' \\
            | awk '{printf "%i", (\$4+\$5)/2 }')
        """
}
