process  REPORT {
    tag ""
    label 'process_low'
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'oras://community.wave.seqera.io/library/r-plotly_r-quarto_r-tidyverse:8753a9619b69e673' :
        'community.wave.seqera.io/library/r-plotly_r-quarto_r-tidyverse:e9368f7ceff3e197' }"
    input:
        path  qmdir_files, stageAs: "*"
        path  nanoq_files, stageAs: "data/nanoq/*"
        path  jelly_files, stageAs: "data/genomescope/*" // these are genomescope files, but that is a long name
        path  quast_files, stageAs: "data/quast/*"
        path  busco_files, stageAs: "data/busco/*"
        path  meryl_files, stageAs: "data/merqury/*" // these are actually merqury files, but that would break the 5 letter scheme.



    output:
        tuple path("report.html"), path("report_files/*")  , emit: report_html
        path("busco_files/reports.csv")                    , emit: busco_table, optional: true
        path("quast_files/reports.csv")                    , emit: quast_table, optional: true


    when:
    task.ext.when == null || task.ext.when

    script:
    def report_profile = "--profile base"
    if(params.ont) report_profile = report_profile << ",nanoq"
    if(params.quast) report_profile = report_profile << ",quast"
    if(params.busco) report_profile = report_profile << ",busco"
    if(params.jellyfish) report_profile = report_profile << ",jellyfish"
    if(params.meryl) report_profile = report_profile << ",merqury"
    """
    quarto render report.qmd \\
        ${report_profile} \\
        --to dashboard
    """
}