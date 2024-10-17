# . pipeline parameters



## Generic options

Less common options for the pipeline, typically set in a config file.

| Parameter | Description | Type | Default | Required | Hidden |
|-----------|-----------|-----------|-----------|-----------|-----------|
| `publish_dir_mode` | Method used to save pipeline results to output directory. <details><summary>Help</summary><small>The Nextflow `publishDir` option specifies which intermediate files should be saved to the output directory. This option tells the pipeline what method should be used to move these files. See [Nextflow docs](https://www.nextflow.io/docs/latest/process.html#publishdir) for details.</small></details>| `string` | copy |  | True |

## Other parameters

| Parameter | Description | Type | Default | Required | Hidden |
|-----------|-----------|-----------|-----------|-----------|-----------|
| `samplesheet` |  | `string` | None |  |  |
| `enable_conda` |  | `string` | None |  |  |
| `collect` |  | `string` | None |  |  |
| `skip_flye` |  | `string` | None |  |  |
| `skip_alignments` |  | `string` | None |  |  |
| `flye_mode` |  | `string` | None |  |  |
| `flye_args` |  | `string` | None |  |  |
| `polish_pilon` |  | `string` | None |  |  |
| `medaka_model` |  | `string` | None |  |  |
| `lift_annotations` |  | `string` | None |  |  |
| `out` |  | `string` | None |  |  |
| `scaffold_ragtag` |  | `string` | None |  |  |
| `scaffold_links` |  | `string` | None |  |  |
| `scaffold_slr` |  | `string` | None |  |  |
