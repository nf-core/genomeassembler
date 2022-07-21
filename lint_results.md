## `nf-core lint` overall result: Failed :x:

Posted for pipeline commit 1e3ba2d

```diff
+| ✅ 141 tests passed       |+
!| ❗  18 tests had warnings |!
-| ❌   6 tests failed       |-
```

<details>

### :x: Test failures:

* [nextflow_config](https://nf-co.re/tools-docs/lint_tests/nextflow_config.html) - Config ``dag.file`` did not end with ``.html``
* [files_unchanged](https://nf-co.re/tools-docs/lint_tests/files_unchanged.html) - `LICENSE` does not match the template
* [files_unchanged](https://nf-co.re/tools-docs/lint_tests/files_unchanged.html) - `.github/workflows/branch.yml` does not match the template
* [files_unchanged](https://nf-co.re/tools-docs/lint_tests/files_unchanged.html) - `.github/workflows/linting_comment.yml` does not match the template
* [files_unchanged](https://nf-co.re/tools-docs/lint_tests/files_unchanged.html) - `.github/workflows/linting.yml` does not match the template
* [files_unchanged](https://nf-co.re/tools-docs/lint_tests/files_unchanged.html) - `assets/email_template.html` does not match the template

### :heavy_exclamation_mark: Test warnings:

* [pipeline_todos](https://nf-co.re/tools-docs/lint_tests/pipeline_todos.html) - TODO string in `README.md`: _Write a 1-2 sentence summary of what data the pipeline is for and what it does_
* [pipeline_todos](https://nf-co.re/tools-docs/lint_tests/pipeline_todos.html) - TODO string in `README.md`: _Add full-sized test dataset and amend the paragraph below if applicable_
* [pipeline_todos](https://nf-co.re/tools-docs/lint_tests/pipeline_todos.html) - TODO string in `README.md`: _Fill in short bullet-pointed list of the default steps in the pipeline_
* [pipeline_todos](https://nf-co.re/tools-docs/lint_tests/pipeline_todos.html) - TODO string in `README.md`: _Update the example "typical command" below used to run the pipeline_
* [pipeline_todos](https://nf-co.re/tools-docs/lint_tests/pipeline_todos.html) - TODO string in `README.md`: _If applicable, make list of people who have also contributed_
* [pipeline_todos](https://nf-co.re/tools-docs/lint_tests/pipeline_todos.html) - TODO string in `README.md`: _Add citation for pipeline after first release. Uncomment lines below and update Zenodo doi and badge at the top of this file._
* [pipeline_todos](https://nf-co.re/tools-docs/lint_tests/pipeline_todos.html) - TODO string in `README.md`: _Add bibliography of tools and data used in your pipeline_
* [pipeline_todos](https://nf-co.re/tools-docs/lint_tests/pipeline_todos.html) - TODO string in `nextflow.config`: _Specify your pipeline's command line flags_
* [pipeline_todos](https://nf-co.re/tools-docs/lint_tests/pipeline_todos.html) - TODO string in `awsfulltest.yml`: _You can customise AWS full pipeline tests as required_
* [pipeline_todos](https://nf-co.re/tools-docs/lint_tests/pipeline_todos.html) - TODO string in `ci.yml`: _You can customise CI pipeline run tests as required_
* [pipeline_todos](https://nf-co.re/tools-docs/lint_tests/pipeline_todos.html) - TODO string in `base.config`: _Check the defaults for all processes_
* [pipeline_todos](https://nf-co.re/tools-docs/lint_tests/pipeline_todos.html) - TODO string in `base.config`: _Customise requirements for specific processes._
* [pipeline_todos](https://nf-co.re/tools-docs/lint_tests/pipeline_todos.html) - TODO string in `test_full.config`: _Specify the paths to your full test data ( on nf-core/test-datasets or directly in repositories, e.g. SRA)_
* [pipeline_todos](https://nf-co.re/tools-docs/lint_tests/pipeline_todos.html) - TODO string in `test_full.config`: _Give any required params for the test so that command line flags are not needed_
* [pipeline_todos](https://nf-co.re/tools-docs/lint_tests/pipeline_todos.html) - TODO string in `output.md`: _Write this documentation describing your workflow's output_
* [pipeline_todos](https://nf-co.re/tools-docs/lint_tests/pipeline_todos.html) - TODO string in `usage.md`: _Add documentation about anything specific to running your pipeline. For general topics, please point to (and add to) the main nf-core website._
* [pipeline_todos](https://nf-co.re/tools-docs/lint_tests/pipeline_todos.html) - TODO string in `WorkflowMain.groovy`: _Add Zenodo DOI for pipeline after first release_
* [pipeline_todos](https://nf-co.re/tools-docs/lint_tests/pipeline_todos.html) - TODO string in `genomeassembler.nf`: _Add all file path parameters for the pipeline to the list below_

### :white_check_mark: Tests passed:

* [files_exist](https://nf-co.re/tools-docs/lint_tests/files_exist.html) - File found: `.gitattributes`
* [files_exist](https://nf-co.re/tools-docs/lint_tests/files_exist.html) - File found: `.gitignore`
* [files_exist](https://nf-co.re/tools-docs/lint_tests/files_exist.html) - File found: `.nf-core.yml`
* [files_exist](https://nf-co.re/tools-docs/lint_tests/files_exist.html) - File found: `.editorconfig`
* [files_exist](https://nf-co.re/tools-docs/lint_tests/files_exist.html) - File found: `.prettierrc.yml`
* [files_exist](https://nf-co.re/tools-docs/lint_tests/files_exist.html) - File found: `CHANGELOG.md`
* [files_exist](https://nf-co.re/tools-docs/lint_tests/files_exist.html) - File found: `CITATIONS.md`
* [files_exist](https://nf-co.re/tools-docs/lint_tests/files_exist.html) - File found: `CODE_OF_CONDUCT.md`
* [files_exist](https://nf-co.re/tools-docs/lint_tests/files_exist.html) - File found: `CODE_OF_CONDUCT.md`
* [files_exist](https://nf-co.re/tools-docs/lint_tests/files_exist.html) - File found: `LICENSE` or `LICENSE.md` or `LICENCE` or `LICENCE.md`
* [files_exist](https://nf-co.re/tools-docs/lint_tests/files_exist.html) - File found: `nextflow_schema.json`
* [files_exist](https://nf-co.re/tools-docs/lint_tests/files_exist.html) - File found: `nextflow.config`
* [files_exist](https://nf-co.re/tools-docs/lint_tests/files_exist.html) - File found: `README.md`
* [files_exist](https://nf-co.re/tools-docs/lint_tests/files_exist.html) - File found: `.github/.dockstore.yml`
* [files_exist](https://nf-co.re/tools-docs/lint_tests/files_exist.html) - File found: `.github/CONTRIBUTING.md`
* [files_exist](https://nf-co.re/tools-docs/lint_tests/files_exist.html) - File found: `.github/ISSUE_TEMPLATE/bug_report.yml`
* [files_exist](https://nf-co.re/tools-docs/lint_tests/files_exist.html) - File found: `.github/ISSUE_TEMPLATE/config.yml`
* [files_exist](https://nf-co.re/tools-docs/lint_tests/files_exist.html) - File found: `.github/ISSUE_TEMPLATE/feature_request.yml`
* [files_exist](https://nf-co.re/tools-docs/lint_tests/files_exist.html) - File found: `.github/PULL_REQUEST_TEMPLATE.md`
* [files_exist](https://nf-co.re/tools-docs/lint_tests/files_exist.html) - File found: `.github/workflows/branch.yml`
* [files_exist](https://nf-co.re/tools-docs/lint_tests/files_exist.html) - File found: `.github/workflows/ci.yml`
* [files_exist](https://nf-co.re/tools-docs/lint_tests/files_exist.html) - File found: `.github/workflows/linting_comment.yml`
* [files_exist](https://nf-co.re/tools-docs/lint_tests/files_exist.html) - File found: `.github/workflows/linting.yml`
* [files_exist](https://nf-co.re/tools-docs/lint_tests/files_exist.html) - File found: `assets/email_template.html`
* [files_exist](https://nf-co.re/tools-docs/lint_tests/files_exist.html) - File found: `assets/email_template.txt`
* [files_exist](https://nf-co.re/tools-docs/lint_tests/files_exist.html) - File found: `assets/sendmail_template.txt`
* [files_exist](https://nf-co.re/tools-docs/lint_tests/files_exist.html) - File found: `assets/nf-core-genomeassembler_logo_light.png`
* [files_exist](https://nf-co.re/tools-docs/lint_tests/files_exist.html) - File found: `conf/modules.config`
* [files_exist](https://nf-co.re/tools-docs/lint_tests/files_exist.html) - File found: `conf/test.config`
* [files_exist](https://nf-co.re/tools-docs/lint_tests/files_exist.html) - File found: `conf/test_full.config`
* [files_exist](https://nf-co.re/tools-docs/lint_tests/files_exist.html) - File found: `docs/images/nf-core-genomeassembler_logo_light.png`
* [files_exist](https://nf-co.re/tools-docs/lint_tests/files_exist.html) - File found: `docs/images/nf-core-genomeassembler_logo_dark.png`
* [files_exist](https://nf-co.re/tools-docs/lint_tests/files_exist.html) - File found: `docs/output.md`
* [files_exist](https://nf-co.re/tools-docs/lint_tests/files_exist.html) - File found: `docs/README.md`
* [files_exist](https://nf-co.re/tools-docs/lint_tests/files_exist.html) - File found: `docs/README.md`
* [files_exist](https://nf-co.re/tools-docs/lint_tests/files_exist.html) - File found: `docs/usage.md`
* [files_exist](https://nf-co.re/tools-docs/lint_tests/files_exist.html) - File found: `lib/nfcore_external_java_deps.jar`
* [files_exist](https://nf-co.re/tools-docs/lint_tests/files_exist.html) - File found: `lib/NfcoreSchema.groovy`
* [files_exist](https://nf-co.re/tools-docs/lint_tests/files_exist.html) - File found: `lib/NfcoreTemplate.groovy`
* [files_exist](https://nf-co.re/tools-docs/lint_tests/files_exist.html) - File found: `lib/Utils.groovy`
* [files_exist](https://nf-co.re/tools-docs/lint_tests/files_exist.html) - File found: `lib/WorkflowMain.groovy`
* [files_exist](https://nf-co.re/tools-docs/lint_tests/files_exist.html) - File found: `main.nf`
* [files_exist](https://nf-co.re/tools-docs/lint_tests/files_exist.html) - File found: `assets/multiqc_config.yml`
* [files_exist](https://nf-co.re/tools-docs/lint_tests/files_exist.html) - File found: `conf/base.config`
* [files_exist](https://nf-co.re/tools-docs/lint_tests/files_exist.html) - File found: `conf/igenomes.config`
* [files_exist](https://nf-co.re/tools-docs/lint_tests/files_exist.html) - File found: `.github/workflows/awstest.yml`
* [files_exist](https://nf-co.re/tools-docs/lint_tests/files_exist.html) - File found: `.github/workflows/awsfulltest.yml`
* [files_exist](https://nf-co.re/tools-docs/lint_tests/files_exist.html) - File found: `lib/WorkflowGenomeassembler.groovy`
* [files_exist](https://nf-co.re/tools-docs/lint_tests/files_exist.html) - File found: `modules.json`
* [files_exist](https://nf-co.re/tools-docs/lint_tests/files_exist.html) - File not found check: `Singularity`
* [files_exist](https://nf-co.re/tools-docs/lint_tests/files_exist.html) - File not found check: `parameters.settings.json`
* [files_exist](https://nf-co.re/tools-docs/lint_tests/files_exist.html) - File not found check: `.nf-core.yaml`
* [files_exist](https://nf-co.re/tools-docs/lint_tests/files_exist.html) - File not found check: `bin/markdown_to_html.r`
* [files_exist](https://nf-co.re/tools-docs/lint_tests/files_exist.html) - File not found check: `conf/aws.config`
* [files_exist](https://nf-co.re/tools-docs/lint_tests/files_exist.html) - File not found check: `.github/workflows/push_dockerhub.yml`
* [files_exist](https://nf-co.re/tools-docs/lint_tests/files_exist.html) - File not found check: `.github/ISSUE_TEMPLATE/bug_report.md`
* [files_exist](https://nf-co.re/tools-docs/lint_tests/files_exist.html) - File not found check: `.github/ISSUE_TEMPLATE/feature_request.md`
* [files_exist](https://nf-co.re/tools-docs/lint_tests/files_exist.html) - File not found check: `docs/images/nf-core-genomeassembler_logo.png`
* [files_exist](https://nf-co.re/tools-docs/lint_tests/files_exist.html) - File not found check: `.markdownlint.yml`
* [files_exist](https://nf-co.re/tools-docs/lint_tests/files_exist.html) - File not found check: `.yamllint.yml`
* [files_exist](https://nf-co.re/tools-docs/lint_tests/files_exist.html) - File not found check: `.travis.yml`
* [nextflow_config](https://nf-co.re/tools-docs/lint_tests/nextflow_config.html) - Config variable found: `manifest.name`
* [nextflow_config](https://nf-co.re/tools-docs/lint_tests/nextflow_config.html) - Config variable found: `manifest.nextflowVersion`
* [nextflow_config](https://nf-co.re/tools-docs/lint_tests/nextflow_config.html) - Config variable found: `manifest.description`
* [nextflow_config](https://nf-co.re/tools-docs/lint_tests/nextflow_config.html) - Config variable found: `manifest.version`
* [nextflow_config](https://nf-co.re/tools-docs/lint_tests/nextflow_config.html) - Config variable found: `manifest.homePage`
* [nextflow_config](https://nf-co.re/tools-docs/lint_tests/nextflow_config.html) - Config variable found: `timeline.enabled`
* [nextflow_config](https://nf-co.re/tools-docs/lint_tests/nextflow_config.html) - Config variable found: `trace.enabled`
* [nextflow_config](https://nf-co.re/tools-docs/lint_tests/nextflow_config.html) - Config variable found: `report.enabled`
* [nextflow_config](https://nf-co.re/tools-docs/lint_tests/nextflow_config.html) - Config variable found: `dag.enabled`
* [nextflow_config](https://nf-co.re/tools-docs/lint_tests/nextflow_config.html) - Config variable found: `process.cpus`
* [nextflow_config](https://nf-co.re/tools-docs/lint_tests/nextflow_config.html) - Config variable found: `process.memory`
* [nextflow_config](https://nf-co.re/tools-docs/lint_tests/nextflow_config.html) - Config variable found: `process.time`
* [nextflow_config](https://nf-co.re/tools-docs/lint_tests/nextflow_config.html) - Config variable found: `params.outdir`
* [nextflow_config](https://nf-co.re/tools-docs/lint_tests/nextflow_config.html) - Config variable found: `params.input`
* [nextflow_config](https://nf-co.re/tools-docs/lint_tests/nextflow_config.html) - Config variable found: `params.show_hidden_params`
* [nextflow_config](https://nf-co.re/tools-docs/lint_tests/nextflow_config.html) - Config variable found: `params.schema_ignore_params`
* [nextflow_config](https://nf-co.re/tools-docs/lint_tests/nextflow_config.html) - Config variable found: `manifest.mainScript`
* [nextflow_config](https://nf-co.re/tools-docs/lint_tests/nextflow_config.html) - Config variable found: `timeline.file`
* [nextflow_config](https://nf-co.re/tools-docs/lint_tests/nextflow_config.html) - Config variable found: `trace.file`
* [nextflow_config](https://nf-co.re/tools-docs/lint_tests/nextflow_config.html) - Config variable found: `report.file`
* [nextflow_config](https://nf-co.re/tools-docs/lint_tests/nextflow_config.html) - Config variable found: `dag.file`
* [nextflow_config](https://nf-co.re/tools-docs/lint_tests/nextflow_config.html) - Config variable (correctly) not found: `params.version`
* [nextflow_config](https://nf-co.re/tools-docs/lint_tests/nextflow_config.html) - Config variable (correctly) not found: `params.nf_required_version`
* [nextflow_config](https://nf-co.re/tools-docs/lint_tests/nextflow_config.html) - Config variable (correctly) not found: `params.container`
* [nextflow_config](https://nf-co.re/tools-docs/lint_tests/nextflow_config.html) - Config variable (correctly) not found: `params.singleEnd`
* [nextflow_config](https://nf-co.re/tools-docs/lint_tests/nextflow_config.html) - Config variable (correctly) not found: `params.igenomesIgnore`
* [nextflow_config](https://nf-co.re/tools-docs/lint_tests/nextflow_config.html) - Config variable (correctly) not found: `params.name`
* [nextflow_config](https://nf-co.re/tools-docs/lint_tests/nextflow_config.html) - Config ``timeline.enabled`` had correct value: ``true``
* [nextflow_config](https://nf-co.re/tools-docs/lint_tests/nextflow_config.html) - Config ``report.enabled`` had correct value: ``true``
* [nextflow_config](https://nf-co.re/tools-docs/lint_tests/nextflow_config.html) - Config ``trace.enabled`` had correct value: ``true``
* [nextflow_config](https://nf-co.re/tools-docs/lint_tests/nextflow_config.html) - Config ``dag.enabled`` had correct value: ``true``
* [nextflow_config](https://nf-co.re/tools-docs/lint_tests/nextflow_config.html) - Config ``manifest.name`` began with ``nf-core/``
* [nextflow_config](https://nf-co.re/tools-docs/lint_tests/nextflow_config.html) - Config variable ``manifest.homePage`` began with https://github.com/nf-core/
* [nextflow_config](https://nf-co.re/tools-docs/lint_tests/nextflow_config.html) - Config variable ``manifest.nextflowVersion`` started with >= or !>=
* [nextflow_config](https://nf-co.re/tools-docs/lint_tests/nextflow_config.html) - Config ``manifest.version`` ends in ``dev``: ``'1.0dev'``
* [nextflow_config](https://nf-co.re/tools-docs/lint_tests/nextflow_config.html) - Config `params.custom_config_version` is set to `master`
* [nextflow_config](https://nf-co.re/tools-docs/lint_tests/nextflow_config.html) - Config `params.custom_config_base` is set to `https://raw.githubusercontent.com/nf-core/configs/master`
* [nextflow_config](https://nf-co.re/tools-docs/lint_tests/nextflow_config.html) - Lines for loading custom profiles found
* [files_unchanged](https://nf-co.re/tools-docs/lint_tests/files_unchanged.html) - `.gitattributes` matches the template
* [files_unchanged](https://nf-co.re/tools-docs/lint_tests/files_unchanged.html) - `.prettierrc.yml` matches the template
* [files_unchanged](https://nf-co.re/tools-docs/lint_tests/files_unchanged.html) - `CODE_OF_CONDUCT.md` matches the template
* [files_unchanged](https://nf-co.re/tools-docs/lint_tests/files_unchanged.html) - `.github/.dockstore.yml` matches the template
* [files_unchanged](https://nf-co.re/tools-docs/lint_tests/files_unchanged.html) - `.github/CONTRIBUTING.md` matches the template
* [files_unchanged](https://nf-co.re/tools-docs/lint_tests/files_unchanged.html) - `.github/ISSUE_TEMPLATE/bug_report.yml` matches the template
* [files_unchanged](https://nf-co.re/tools-docs/lint_tests/files_unchanged.html) - `.github/ISSUE_TEMPLATE/config.yml` matches the template
* [files_unchanged](https://nf-co.re/tools-docs/lint_tests/files_unchanged.html) - `.github/ISSUE_TEMPLATE/feature_request.yml` matches the template
* [files_unchanged](https://nf-co.re/tools-docs/lint_tests/files_unchanged.html) - `.github/PULL_REQUEST_TEMPLATE.md` matches the template
* [files_unchanged](https://nf-co.re/tools-docs/lint_tests/files_unchanged.html) - `assets/email_template.txt` matches the template
* [files_unchanged](https://nf-co.re/tools-docs/lint_tests/files_unchanged.html) - `assets/sendmail_template.txt` matches the template
* [files_unchanged](https://nf-co.re/tools-docs/lint_tests/files_unchanged.html) - `assets/nf-core-genomeassembler_logo_light.png` matches the template
* [files_unchanged](https://nf-co.re/tools-docs/lint_tests/files_unchanged.html) - `docs/images/nf-core-genomeassembler_logo_light.png` matches the template
* [files_unchanged](https://nf-co.re/tools-docs/lint_tests/files_unchanged.html) - `docs/images/nf-core-genomeassembler_logo_dark.png` matches the template
* [files_unchanged](https://nf-co.re/tools-docs/lint_tests/files_unchanged.html) - `docs/README.md` matches the template
* [files_unchanged](https://nf-co.re/tools-docs/lint_tests/files_unchanged.html) - `lib/nfcore_external_java_deps.jar` matches the template
* [files_unchanged](https://nf-co.re/tools-docs/lint_tests/files_unchanged.html) - `lib/NfcoreSchema.groovy` matches the template
* [files_unchanged](https://nf-co.re/tools-docs/lint_tests/files_unchanged.html) - `lib/NfcoreTemplate.groovy` matches the template
* [files_unchanged](https://nf-co.re/tools-docs/lint_tests/files_unchanged.html) - `.gitignore` matches the template
* [actions_ci](https://nf-co.re/tools-docs/lint_tests/actions_ci.html) - '.github/workflows/ci.yml' is triggered on expected events
* [actions_ci](https://nf-co.re/tools-docs/lint_tests/actions_ci.html) - '.github/workflows/ci.yml' checks minimum NF version
* [actions_awstest](https://nf-co.re/tools-docs/lint_tests/actions_awstest.html) - '.github/workflows/awstest.yml' is triggered correctly
* [actions_awsfulltest](https://nf-co.re/tools-docs/lint_tests/actions_awsfulltest.html) - `.github/workflows/awsfulltest.yml` is triggered correctly
* [actions_awsfulltest](https://nf-co.re/tools-docs/lint_tests/actions_awsfulltest.html) - `.github/workflows/awsfulltest.yml` does not use `-profile test`
* [readme](https://nf-co.re/tools-docs/lint_tests/readme.html) - README Nextflow minimum version badge matched config. Badge: `21.10.3`, Config: `21.10.3`
* [readme](https://nf-co.re/tools-docs/lint_tests/readme.html) - README Nextflow minimum version in Quick Start section matched config. README: `21.10.3`, Config: `21.10.3`
* [pipeline_name_conventions](https://nf-co.re/tools-docs/lint_tests/pipeline_name_conventions.html) - Name adheres to nf-core convention
* [template_strings](https://nf-co.re/tools-docs/lint_tests/template_strings.html) - Did not find any Jinja template strings (71 files)
* [schema_lint](https://nf-co.re/tools-docs/lint_tests/schema_lint.html) - Schema lint passed
* [schema_lint](https://nf-co.re/tools-docs/lint_tests/schema_lint.html) - Schema title + description lint passed
* [schema_params](https://nf-co.re/tools-docs/lint_tests/schema_params.html) - Schema matched params returned from nextflow config
* [actions_schema_validation](https://nf-co.re/tools-docs/lint_tests/actions_schema_validation.html) - Workflow validation passed: awsfulltest.yml
* [actions_schema_validation](https://nf-co.re/tools-docs/lint_tests/actions_schema_validation.html) - Workflow validation passed: awstest.yml
* [actions_schema_validation](https://nf-co.re/tools-docs/lint_tests/actions_schema_validation.html) - Workflow validation passed: branch.yml
* [actions_schema_validation](https://nf-co.re/tools-docs/lint_tests/actions_schema_validation.html) - Workflow validation passed: ci.yml
* [actions_schema_validation](https://nf-co.re/tools-docs/lint_tests/actions_schema_validation.html) - Workflow validation passed: linting.yml
* [actions_schema_validation](https://nf-co.re/tools-docs/lint_tests/actions_schema_validation.html) - Workflow validation passed: linting_comment.yml
* [merge_markers](https://nf-co.re/tools-docs/lint_tests/merge_markers.html) - No merge markers found in pipeline files
* [modules_json](https://nf-co.re/tools-docs/lint_tests/modules_json.html) - Only installed modules found in `modules.json`
* [multiqc_config](https://nf-co.re/tools-docs/lint_tests/multiqc_config.html) - 'assets/multiqc_config.yml' follows the ordering scheme of the minimally required plugins.
* [multiqc_config](https://nf-co.re/tools-docs/lint_tests/multiqc_config.html) - 'assets/multiqc_config.yml' contains a matching 'report_comment'.
* [multiqc_config](https://nf-co.re/tools-docs/lint_tests/multiqc_config.html) - 'assets/multiqc_config.yml' contains 'export_plots: true'.

### Run details

* nf-core/tools version 2.4.1
* Run at `2022-07-21 13:18:40`

</details>
