process REPORT {
    tag "REPORT"
    label 'process_low'
    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine in ['singularity', 'apptainer'] && !task.ext.singularity_pull_docker_container
?         'https://community-cr-prod.seqera.io/docker/registry/v2/blobs/sha256/62/62cee220a91255a09aa10b25f920b6b68febe137c7ed00b527d5891a3e5c7842/data'
:         'community.wave.seqera.io/library/ca-certificates_quarto_r-gt_r-plotly_pruned:833048f01b6491fc' }"

    input:
    path qmdir_files,       stageAs: "*"
    path funct_files,       stageAs: "functions/*"
    path script_files,      stageAs: "scripts/*"
    path fastplong_files,   stageAs: "data/fastplong/*"
    path jelly_files,       stageAs: "data/genomescope/*"
    path quast_files,       stageAs: "data/quast/*"
    path busco_files,       stageAs: "data/busco/*"
    path meryl_files,       stageAs: "data/merqury/*"
    val versions
    val groups

    output:
    path("report.html"), emit: report_html
    path ("busco_files/reports.csv"), emit: busco_table, optional: true
    path ("quast_files/reports.csv"), emit: quast_table, optional: true
    path ("genomescope_files/*"), emit: genomescope_plots, optional: true
    // Versions are not pushed to versions topic as it is an input.
    tuple val("${task.process}"), val('R'), eval("R --version | head -n1 | sed 's/R version //; s/ .*//'"), emit: versions_R
    tuple val("${task.process}"), val('r-tidyverse'), eval("ls /opt/conda/pkgs/ | grep tidyverse | sed 's/r-tidyverse-//; s/-.*//'"), emit: versions_tidyverse
    tuple val("${task.process}"), val('r-plotly'), eval("ls /opt/conda/pkgs/ | grep plotly | sed 's/r-plotly-//; s/-.*//'"), emit: versions_plotly
    tuple val("${task.process}"), val('r-quarto'), eval("ls /opt/conda/pkgs/ | grep r-quarto | sed 's/r-quarto-//; s/-.*//'"), emit: versions_rquarto
    tuple val("${task.process}"), val('quarto-cli'), eval("quarto --version"), emit: versions_quartocli
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
    groupBuilder.call(groups)
    def group_content = groupBuilder.toString().tokenize('\n').join("\n    ")
    def versionBuilder = new groovy.yaml.YamlBuilder()
    versionBuilder.call(versions)
    def versions_content = versionBuilder.toString().tokenize('\n').join("\n    ")
    """
    cat <<- END_YAML_GROUPS > groups.yml
    ${group_content}
    END_YAML_GROUPS
    cat <<- END_YAML_VERSIONS > versions.yml
    ${versions_content}
    END_YAML_VERSIONS
    # Set environment variables needed for Quarto rendering
    export XDG_CACHE_HOME="./.xdg_cache_home"
    export XDG_DATA_HOME="./.xdg_data_home"
    export HOME="\$PWD"
    mkdir -p "\$HOME/.cache"
    mkdir -p "\$HOME/tmp"
    export TMPDIR="\$HOME/tmp"
    export TEMP="\$TMPDIR"
    export TMP="\$TMPDIR"

    # Fix Quarto for Apptainer (see https://community.seqera.io/t/confusion-over-why-a-tool-works-in-docker-but-fails-in-singularity-when-the-installation-doesnt-differ-i-e-using-wave-micromamba/1244)
    ENV_QUARTO=/opt/conda/etc/conda/activate.d/quarto.sh
    set +u
    if [ -z "\${QUARTO_DENO}" ] && [ -f "\${ENV_QUARTO}" ]; then
        source "\${ENV_QUARTO}"
    fi
    set -u

    # Set parallelism for BLAS/MKL etc. to avoid over-booking of resources
    export MKL_NUM_THREADS="${task.cpus}"
    export OPENBLAS_NUM_THREADS="${task.cpus}"
    export OMP_NUM_THREADS="${task.cpus}"
    export NUMBA_NUM_THREADS="${task.cpus}"

    export HOME="\$PWD"
    LC_ALL=C.UTF-8 quarto render report.qmd \\
        ${report_profile} \\
        ${report_params}
    """
    stub:
    """
    mkdir report_files && touch report_files/file.txt
    touch report.html
    mkdir busco_files && touch busco_files/reports.csv
    mkdir quast_files && touch quast_files/reports.csv
    mkdir genomescope_files && touch genomescope_files/file.txt
    """
}
