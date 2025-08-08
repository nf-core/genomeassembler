process REPORT {
    tag "REPORT"
    label 'process_low'
    conda "${moduleDir}/environment.yml"
    container "${workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container
        ? 'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/89/8967e1cb830fdc77ec5b84541a50c74a0a05eaaae557314490809de2fc91e4af/data'
        : 'community.wave.seqera.io/library/quarto_r-gt_r-plotly_r-quarto_pruned:be4a8863b7b76cf7'}"
    /* wave builds:
    https://wave.seqera.io/view/builds/bd-6e20dd9b9b77f359_1 singularity
    https://wave.seqera.io/view/builds/bd-be4a8863b7b76cf7_1 docker
    */
    input:
    path qmdir_files,       stageAs: "*"
    path funct_files,       stageAs: "functions/*"
    path fastplong_files,   stageAs: "data/fastplong/*"
    path jelly_files,       stageAs: "data/genomescope/*"
    path quast_files,       stageAs: "data/quast/*"
    path busco_files,       stageAs: "data/busco/*"
    path meryl_files,       stageAs: "data/merqury/*"
    path versions,          stageAs: "software_versions.yml"
    val groups

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
    def report_params = ''
    if (fastplong_files) {
        report_profile = report_profile << ",fastplong"
        report_params  = report_params << ' -P fastplong:true'
    }
    if (quast_files) {
        report_profile = report_profile << ",quast"
        report_params  = report_params << ' -P quast:true '
    }
    if (busco_files) {
        report_profile = report_profile << ",busco"
        report_params  = report_params << ' -P busco:true'
    }
    if (jelly_files) {
        report_profile = report_profile << ",jellyfish"
        report_params  = report_params << ' -P jellyfish:true'
    }
    if (meryl_files) {
        report_profile = report_profile << ",merqury"
        report_params  = report_params << ' -P merqury:true'
    }

    def groupBuilder = new groovy.yaml.YamlBuilder()
    groupBuilder(groups)
    def group_content = groupBuilder.toString().tokenize('\n').join("\n    ")
    """
    cat <<- END_YAML_GROUPS > groups.yml
    ${group_content}
    END_YAML_GROUPS

    export HOME="\$PWD"
    quarto render report.qmd \\
        ${report_profile} \\
        ${report_params} \\
        --to dashboard

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        R: \$(R --version | head -n1 | sed 's/R version //; s/ .*//')
        r-tidyverse: \$(ls /opt/conda/pkgs/ | grep tidyverse | sed 's/r-tidyverse-//; s/-.*//')
        r-plotly: \$(ls /opt/conda/pkgs/ | grep plotly | sed 's/r-plotly-//; s/-.*//')
        r-quarto: \$(ls /opt/conda/pkgs/ | grep r-quarto | sed 's/r-quarto-//; s/-.*//')
        quarto-cli: \$(quarto --version)
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
        R: \$(R --version | head -n1 | sed 's/R version //; s/ .*//')
        r-tidyverse: \$(ls /opt/conda/pkgs/ | grep tidyverse | sed 's/r-tidyverse-//; s/-.*//')
        r-plotly: \$(ls /opt/conda/pkgs/ | grep plotly | sed 's/r-plotly-//; s/-.*//')
        r-quarto: \$(ls /opt/conda/pkgs/ | grep r-quarto | sed 's/r-quarto-//; s/-.*//')
        quarto-cli: \$(quarto --version)
    END_VERSIONS
    """
}
