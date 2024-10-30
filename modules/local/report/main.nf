process  ALL_SAMPLES {
    tag "$meta.id"
    label 'process_low'
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'oras://community.wave.seqera.io/library/r-plotly_r-quarto_r-tidyverse:8753a9619b69e673' :
        'community.wave.seqera.io/library/r-plotly_r-quarto_r-tidyverse:e9368f7ceff3e197' }"
    input:
    tuple val(meta), path(files)

    output:
    tuple val(meta), path("all_sample_report.html"), path("all_sample_report/*")       , emit: report

    when:
    task.ext.when == null || task.ext.when

    script:
    def report_profile = "--profile "
    if(params.ont) report_profile = report_profile << "nanoq,"
    if(params.quast) report_profile = report_profile << "quast,"
    if(params.busco) report_profile = report_profile << "busco,"
    if(params.yak) report_profile = report_profile << "yak,"
    if(params.meryl) report_profile = report_profile << "meryl,"
    if(params.yak) report_profile = report_profile << "yak,"
    """
    quarto render report.qmd \\
     $report_profile \\
    --to dashboard


    """
}