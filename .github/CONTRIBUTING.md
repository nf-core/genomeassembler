# `nf-core/genomeassembler`: Contributing Guidelines

Hi there!
Many thanks for taking an interest in improving nf-core/genomeassembler.

We try to manage the required tasks for nf-core/genomeassembler using GitHub issues, you probably came to this page when creating one.
Please use the pre-filled template to save time.

However, don't be put off by this template - other more general issues and suggestions are welcome!
Contributions to the code are even more welcome ;)

> [!NOTE]
> If you need help using or modifying nf-core/genomeassembler then the best place to ask is on the nf-core Slack [#genomeassembler](https://nfcore.slack.com/channels/genomeassembler) channel ([join our Slack here](https://nf-co.re/join/slack)).

## Contribution workflow

If you'd like to write some code for nf-core/genomeassembler, the standard workflow is as follows:

1. Check that there isn't already an issue about your idea in the [nf-core/genomeassembler issues](https://github.com/nf-core/genomeassembler/issues) to avoid duplicating work. If there isn't one already, please create one so that others know you're working on this
2. [Fork](https://help.github.com/en/github/getting-started-with-github/fork-a-repo) the [nf-core/genomeassembler repository](https://github.com/nf-core/genomeassembler) to your GitHub account
3. Make the necessary changes / additions within your forked repository following [Pipeline conventions](#pipeline-contribution-conventions)
4. Use `nf-core pipelines schema build` and add any new parameters to the pipeline JSON schema (requires [nf-core tools](https://github.com/nf-core/tools) >= 1.10).
5. Submit a Pull Request against the `dev` branch and wait for the code to be reviewed and merged

If you're not used to this workflow with git, you can start with some [docs from GitHub](https://help.github.com/en/github/collaborating-with-issues-and-pull-requests) or even their [excellent `git` resources](https://try.github.io/).

## Tests

You have the option to test your changes locally by running the pipeline. For receiving warnings about process selectors and other `debug` information, it is recommended to use the debug profile. Execute all the tests with the following command:

```bash
nf-test test --profile debug,test,docker --verbose
```

When you create a pull request with changes, [GitHub Actions](https://github.com/features/actions) will run automatic tests.
Typically, pull-requests are only fully reviewed when these tests are passing, though of course we can help out before then.

There are typically two types of tests that run:

### Lint tests

`nf-core` has a [set of guidelines](https://nf-co.re/developers/guidelines) which all pipelines must adhere to.
To enforce these and ensure that all pipelines stay in sync, we have developed a helper tool which runs checks on the pipeline code. This is in the [nf-core/tools repository](https://github.com/nf-core/tools) and once installed can be run locally with the `nf-core pipelines lint <pipeline-directory>` command.

If any failures or warnings are encountered, please follow the listed URL for more documentation.

### Pipeline tests

Each `nf-core` pipeline should be set up with a minimal set of test-data.
`GitHub Actions` then runs the pipeline on this data to ensure that it exits successfully.
If there are any failures then the automated tests fail.
These tests are run both with the latest available version of `Nextflow` and also the minimum required version that is stated in the pipeline code.

## Patch

:warning: Only in the unlikely and regretful event of a release happening with a bug.

- On your own fork, make a new branch `patch` based on `upstream/main` or `upstream/master`.
- Fix the bug, and bump version (X.Y.Z+1).
- Open a pull-request from `patch` to `main`/`master` with the changes.

## Getting help

For further information/help, please consult the [nf-core/genomeassembler documentation](https://nf-co.re/genomeassembler/usage) and don't hesitate to get in touch on the nf-core Slack [#genomeassembler](https://nfcore.slack.com/channels/genomeassembler) channel ([join our Slack here](https://nf-co.re/join/slack)).

## Pipeline contribution conventions

To make the `nf-core/genomeassembler` code and processing logic more understandable for new contributors and to ensure quality, we semi-standardise the way the code and other contributions are written.

### Adding a new step

If you wish to contribute a new step, please use the following coding standards:

1. Define the corresponding input channel into your new process from the expected previous process channel.
2. Write the process block (see below).
3. Define the output channel if needed (see below).
4. Add any new parameters to `nextflow.config` with a default (see below).
5. Add any new parameters to `nextflow_schema.json` with help text (via the `nf-core pipelines schema build` tool).
6. Add sanity checks and validation for all relevant parameters.
7. Perform local tests to validate that the new code works as expected.
8. If applicable, add a new test in the `tests` directory.
9. Add a description of the output files and if relevant any appropriate images from the MultiQC report to `docs/output.md`.

### Default values

Parameters should be initialised / defined with default values within the `params` scope in `nextflow.config`.

Once there, use `nf-core pipelines schema build` to add to `nextflow_schema.json`.

### Default processes resource requirements

Sensible defaults for process resource requirements (CPUs / memory / time) for a process should be defined in `conf/base.config`. These should generally be specified generic with `withLabel:` selectors so they can be shared across multiple processes/steps of the pipeline. A nf-core standard set of labels that should be followed where possible can be seen in the [nf-core pipeline template](https://github.com/nf-core/tools/blob/main/nf_core/pipeline-template/conf/base.config), which has the default process as a single core-process, and then different levels of multi-core configurations for increasingly large memory requirements defined with standardised labels.

The process resources can be passed on to the tool dynamically within the process with the `${task.cpus}` and `${task.memory}` variables in the `script:` block.

### Naming schemes

Please use the following naming schemes, to make it easy to understand what is going where.

- initial process channel: `ch_output_from_<process>`
- intermediate and terminal channels: `ch_<previousprocess>_for_<nextprocess>`

### Nextflow version bumping

If you are using a new feature from core Nextflow, you may bump the minimum required version of nextflow in the pipeline with: `nf-core pipelines bump-version --nextflow . [min-nf-version]`

### Images and figures

For overview images and other documents we follow the nf-core [style guidelines and examples](https://nf-co.re/developers/design_guidelines).

## GitHub Codespaces

This repo includes a devcontainer configuration which will create a GitHub Codespaces for Nextflow development! This is an online developer environment that runs in your browser, complete with VSCode and a terminal.

To get started:

- Open the repo in [Codespaces](https://github.com/nf-core/genomeassembler/codespaces)
- Tools installed
  - nf-core
  - Nextflow

Devcontainer specs:

- [DevContainer config](.devcontainer/devcontainer.json)

# Pipeline specific conventions

## Parameters

Due to the way the pipeline handles parameterization of inputs, if a parameter is added, the corresponding param needs to also be added to the meta-map constructor in `subworkflows/local/utils_nfcore_genomeassembler_pipeline/main.nf`, and `assets/schema_input.json` and `nextflow_schema.json` need to be updated accordingly.

## Adding a new step

Any steps added to the pipeline need to be compatible with the overall pipeline.
During 'transit', this pipeline makes use of a channel (`ch_main`) that consists of a singular item: the `meta` map.
This is constructed in `subworkflows/local/utils_nfcore_genomeassembler_pipeline/main.nf`.
This map stores _all_ sample information, which includes every parameter.
Every subworkflow has to emit `ch_main`, i.e. a channel that only contains the `meta` map.
All steps that are related to the creation of this map, including handling of conditional execution, need to happen in the subworkflow, to ensure that the full `ch_main` travels through the pipeline.

Below are patterns that are used in this pipeline to do work with `ch_main`.

### Single input

General generation of input for a single input process:

```nextflow
ch_process_in = ch_main
    .map { meta -> [meta, meta.reads] }
SINGLE_INPUT_PROCESS(ch_process_in)
```

General approach to create output and transit `ch_main` channel:

```nextflow
ch_main = SINGLE_INPUT_PROCESS.out.output
    .map{ meta, process_output -> [meta + [process_output_name: process_output]]}
```

> [!NOTE]
> Use `meta - meta.subMap["key"] + [key: value]` to remove an existing item in case it should be updated

### Multi input

General generation of input for a multi input process:

```nextflow
ch_process_multi_in = ch_main
    .multiMap { meta ->
        input_reads: [meta, meta.reads]
        input_ref:   [meta, meta.reference]
    }
MULTI_INPUT_PROCESS(ch_process_multi_in.input_reads ch_process_multi_in.input_ref)
```

### Flow-control

Since the pipeline parameterises per sample, flow control has to be done on channels, via `.branch()`, or `.filter()`.
`.filter()` offers more flexibility, in complex cases, e.g. where samples can be part of multiple groups, while I personally find `.branch()` easier to handle simpler cases.

```nextflow
ch_conditional_process =
    ch_main
        .branch { meta ->
            process_in:   meta.run_conditional_process == "yes"
            process_skip: meta.run_conditional_process != "yes"
        }

conditional_process_in =
    ch_conditional_process.process_in
    //additional modifications via map possible here, see above
CONDITIONAL_PROCESS(conditional_process_in)
```

### Output creation

Ouptputs for conditional channels need to be handled to recreate the whole transit channel, via `.mix()`:

```nextflow
ch_main = ch_conditional_process.process_skip
    .mix(
      CONDITIONAL_PROCESS.out.output
          .map{ meta, process_output ->
            [
              meta + [process_output_name: process_output]
            ]
          }
   )
```

### Grouping

The pipeline implements sample grouping, which is currently only used during read-preprocessing. Samples that share a group will undergo read-preprocessing as a group, i.e. the reads are only processed once.
Grouping works by generating a new `meta.id`, which corresponds to the group, while the `meta`s of the group members are stored in `meta.metas`:

```nextflow
ch_ont_in = ch_main
    // filter for samples that have a group
    .filter { it -> it.meta.group }
    // move group, and required inputs into slots:
    .map { it -> [it.meta, it.meta.group, it.meta.ontreads] }
    // Group by meta.group
    .groupTuple(by: 1)
    // Collect all sample-meta into a group meta slot named metas
    // Use unique reads; user responsible to group correctly
    .map {
         it ->
                [
                    [
                        id: it[1], // the group
                        metas: it[0]
                    ],
                    it[2].unique()[0] // Ontreads
                ]
    }
    // Mix in those samples that are not grouped
    .mix(
      ch_main
          .filter { it -> !it.meta.group }
          .map {
              it -> [ it.meta, it.meta.ontreads, [] ]
          }
        )
ONT_PROCESS(ont_in)
```

After this process has concluded, the group members are regenerated, and ch_main is reconstructed:

```nextflow
ch_main = ONT_PROCESS
    .out
    .output
    .filter { it -> it[0].metas } // metas only exists when grouped.
    .flatMap { it -> // it looks like [meta, output_path]
        it[0].metas
              .collect { metas -> [ meta: metas + [ ontreads_modified: it[1] ] ] }
              // it here is the it from flatMap. Every group member receives the same output.
    }
    .mix(ONT_PROCESS.out.output
        .filter { it -> !it[0].metas }
        .map {
            it -> [ meta: it[0] + [ ontreads_modified: it[1] ] ]
        }
    )
```

### Naming schemes

Please use the following channel naming schemes, to make it easy to understand what is going where.

- transit channel, subworkfow input and output: `ch_main`
- intermediate channels: `ch_descriptive_suffix`
