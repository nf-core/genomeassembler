process REPORT {
    tag "REPORT"
    label 'process_low'
    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container
        ? 'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/90/90fef3481ee574cada2330e149cebab7290724e6b9869d84af66d0fc3d04168e/data'
        : 'community.wave.seqera.io/library/quarto_r-plotly_r-quarto_r-tidyjson_pruned:2712f84a83ca0d9a'}"

    input:
    path qmdir_files, stageAs: "*"
    path funct_files, stageAs: "functions/*"
    path nanoq_files, stageAs: "data/nanoq/*"
    path jelly_files, stageAs: "data/genomescope/*"
    path quast_files, stageAs: "data/quast/*"
    path busco_files, stageAs: "data/busco/*"
    path meryl_files, stageAs: "data/merqury/*"
    path versions, stageAs: "software_versions.yml"

    output:
    tuple path("report.html"), path("report_files/*"), emit: report_html
    path ("busco_files/reports.csv"), emit: busco_table, optional: true
    path ("quast_files/reports.csv"), emit: quast_table, optional: true
    path ("genomescope_files/*"), emit: genomescope_plots, optional: true
    path "versions.yml", emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def report_profile = "--profile base"
    if (params.ont) {
        report_profile = report_profile << ",nanoq"
    }
    if (params.quast) {
        report_profile = report_profile << ",quast"
    }
    if (params.busco) {
        report_profile = report_profile << ",busco"
    }
    if (params.jellyfish) {
        report_profile = report_profile << ",jellyfish"
    }
    if (params.merqury) {
        report_profile = report_profile << ",merqury"
    }
    def report_params = ''
    if (params.ont) {
        report_params = report_params << ' -P nanoq:true'
    }
    if (params.quast) {
        report_params = report_params << ' -P quast:true '
    }
    if (params.busco) {
        report_params = report_params << ' -P busco:true'
    }
    if (params.jellyfish) {
        report_params = report_params << ' -P jellyfish:true'
    }
    if (params.merqury) {
        report_params = report_params << ' -P merqury:true'
    }
    """
    export HOME="\$PWD"
    quarto render report.qmd \\
        ${report_profile} \\
        ${report_params} \\
        --to dashboard

    ## Version needs to be bumped manually

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        report: 1.0.0
    END_VERSIONS
    """
    stub:
    """
    mkdir report_files && touch report_files/file.txt
    touch report.html
    mkdir busco_files && touch busco_files/reports.csv
    mkdir quast_files && touch quast_files/reports.csv
    mkdir genomescope_files && touch genomescope_files/file.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        report: 1.0.0
    END_VERSIONS
    """
}
