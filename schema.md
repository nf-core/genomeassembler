# nf-core/genomeassembler pipeline parameters

Assemble genomes from long ONT or pacbio HiFi reads

## Input/output options

Define where the pipeline should find input data and save output data.

| Parameter                                                                                                                                                                                                                 | Description                                                                                                                                                                                                                                    | Type     | Default | Required | Hidden |
| ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------- | ------- | -------- | ------ |
| `input`                                                                                                                                                                                                                   | Path to comma-separated file containing information about the samples in the experiment. <details><summary>Help</summary><small>You will need to create a design file with information about the samples in your experiment before running the |
| pipeline. Use this parameter to specify its location. It has to be a comma-separated file with 3 columns, and a header row. See [usage docs](https://nf-co.re/genomeassembler/usage#samplesheet-input).</small></details> | `string`                                                                                                                                                                                                                                       |          | True    |          |
| `outdir`                                                                                                                                                                                                                  | The output directory where the results will be saved. You have to use absolute paths to storage on Cloud infrastructure.                                                                                                                       | `string` |         | True     |        |
| `email`                                                                                                                                                                                                                   | Email address for completion summary. <details><summary>Help</summary><small>Set this parameter to your e-mail address to get a summary e-mail with details of the run sent to you when the workflow exits. If set in your user config file    |
| (`~/.nextflow/config`) then you don't need to specify this on the command line for every run.</small></details>                                                                                                           | `string`                                                                                                                                                                                                                                       |          |         |          |

## Institutional config options

Parameters used to describe centralised config profiles. These should not be edited.

| Parameter                                                                                                                                               | Description                                                                                                                                                                                                                               | Type                                                     | Default | Required | Hidden |
| ------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------- | ------- | -------- | ------ |
| `custom_config_version`                                                                                                                                 | Git commit id for Institutional configs.                                                                                                                                                                                                  | `string`                                                 | master  |          | True   |
| `custom_config_base`                                                                                                                                    | Base directory for Institutional configs. <details><summary>Help</summary><small>If you're running offline, Nextflow will not be able to fetch the institutional config files from the internet. If you don't need them, then this is not |
| a problem. If you do need them, you should download the files from the repo and tell Nextflow where to find them with this parameter.</small></details> | `string`                                                                                                                                                                                                                                  | https://raw.githubusercontent.com/nf-core/configs/master |         | True     |
| `config_profile_name`                                                                                                                                   | Institutional config name.                                                                                                                                                                                                                | `string`                                                 |         |          | True   |
| `config_profile_description`                                                                                                                            | Institutional config description.                                                                                                                                                                                                         | `string`                                                 |         |          | True   |
| `config_profile_contact`                                                                                                                                | Institutional config contact information.                                                                                                                                                                                                 | `string`                                                 |         |          | True   |
| `config_profile_url`                                                                                                                                    | Institutional config URL link.                                                                                                                                                                                                            | `string`                                                 |         |          | True   |

## Generic options

Less common options for the pipeline, typically set in a config file.

| Parameter                                                                                                                                                       | Description                                                                                                                                                                                                                                  | Type      | Default                                                  | Required | Hidden |
| --------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | --------- | -------------------------------------------------------- | -------- | ------ |
| `version`                                                                                                                                                       | Display version and exit.                                                                                                                                                                                                                    | `boolean` |                                                          |          | True   |
| `publish_dir_mode`                                                                                                                                              | Method used to save pipeline results to output directory. <details><summary>Help</summary><small>The Nextflow `publishDir` option specifies which intermediate files should be saved to the output directory. This option tells the pipeline |
| what method should be used to move these files. See [Nextflow docs](https://www.nextflow.io/docs/latest/process.html#publishdir) for details.</small></details> | `string`                                                                                                                                                                                                                                     | copy      |                                                          | True     |
| `email_on_fail`                                                                                                                                                 | Email address for completion summary, only when pipeline fails. <details><summary>Help</summary><small>An email address to send a summary email to when the pipeline is completed - ONLY sent if the pipeline does not exit                  |
| successfully.</small></details>                                                                                                                                 | `string`                                                                                                                                                                                                                                     |           |                                                          | True     |
| `plaintext_email`                                                                                                                                               | Send plain-text email instead of HTML.                                                                                                                                                                                                       | `boolean` |                                                          |          | True   |
| `monochrome_logs`                                                                                                                                               | Do not use coloured log outputs.                                                                                                                                                                                                             | `boolean` |                                                          |          | True   |
| `hook_url`                                                                                                                                                      | Incoming hook URL for messaging service <details><summary>Help</summary><small>Incoming hook URL for messaging service. Currently, MS Teams and Slack are supported.</small></details>                                                       | `string`  |                                                          |          | True   |
| `validate_params`                                                                                                                                               | Boolean whether to validate parameters against the schema at runtime                                                                                                                                                                         | `boolean` | True                                                     |          | True   |
| `pipelines_testdata_base_path`                                                                                                                                  | Base URL or local path to location of pipeline test dataset files                                                                                                                                                                            | `string`  | https://raw.githubusercontent.com/nf-core/test-datasets/ |          | True   |

## Reference Parameters

Options controlling pipeline behavior

| Parameter   | Description                                | Type      | Default | Required | Hidden |
| ----------- | ------------------------------------------ | --------- | ------- | -------- | ------ |
| `ref_fasta` | Path to reference genome seqeunce (fasta)  | `string`  |         |          |        |
| `ref_gff`   | Path to reference genome annotations (gff) | `string`  |         |          |        |
| `use_ref`   | use reference genome                       | `boolean` |         |          | True   |

## Assembly options

Options controlling assembly

| Parameter                                         | Description                                                                                                                                                                                                                                         | Type     | Default     | Required | Hidden |
| ------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | -------- | ----------- | -------- | ------ |
| `strategy`                                        | Assembly strategy to use. Valid choices are `'single'`, `'hybrid'` and `'scaffold'`                                                                                                                                                                 | `string` | single      |          |        |
| `assembler`                                       | Assembler to use. Valid choices depend on strategy; for single either `flye` or `hifiasm`, hybrid can be done with `hifiasm` and for scaffolded assembly provide the names of the assemblers separated with an underscore. The first assembler will |
| be used for ONT reads, the second for HiFi reads. | `string`                                                                                                                                                                                                                                            | hifiasm  |             |          |
| `assembly_scaffolding_order`                      | When strategy is "scaffold", which assembly should be scaffolded onto which?                                                                                                                                                                        | `string` | ont_on_hifi |          |        |
| `genome_size`                                     | expected genome size, optional                                                                                                                                                                                                                      | `string` |             |          |        |
| `flye_mode`                                       | flye mode                                                                                                                                                                                                                                           | `string` | --nano-hq   |          |        |
| `flye_args`                                       | additional args for flye                                                                                                                                                                                                                            | `string` |             |          |        |
| `hifiasm_args`                                    | Extra arguments passed to `hifiasm`                                                                                                                                                                                                                 | `string` | ""          |          |        |

## Long-read preprocessing

| Parameter             | Description                                              | Type      | Default | Required | Hidden |
| --------------------- | -------------------------------------------------------- | --------- | ------- | -------- | ------ |
| `ontreads`            | Path to ONT reads                                        | `string`  |         |          |        |
| `ont_collect`         | Collect ONT reads from several files?                    | `boolean` |         |          |        |
| `ont_trim`            | Trim ont reads with fastplong?                           | `boolean` |         |          |        |
| `ont_adapters`        | Adaptors for ONT read-trimming                           | `string`  | []      |          |        |
| `ont_fastplong_args`  | Additional args to be passed to fastplong for ONT reads  | `string`  | ""      |          |        |
| `hifireads`           | Path to HiFi reads                                       | `string`  |         |          |        |
| `hifi_trim`           | Trim HiFi reads with fastplonng                          | `boolean` |         |          |        |
| `hifi_adapters`       | Adaptors for HiFi read-trimming                          | `string`  | []      |          |        |
| `hifi_fastplong_args` | Additional args to be passed to fastplong for HiFi reads | `string`  | ""      |          |        |
| `jellyfish`           | Run jellyfish and genomescope (recommended)              | `boolean` |         |          |        |
| `jellyfish_k`         | Value of k used during k-mer analysis with jellyfish     | `integer` | 21      |          |        |
| `dump`                | dump jellyfish output                                    | `boolean` |         |          |        |

## Polishing options

Polishing options

| Parameter       | Description                                      | Type      | Default | Required | Hidden |
| --------------- | ------------------------------------------------ | --------- | ------- | -------- | ------ |
| `polish_pilon`  | Polish assembly with pilon? Requires short reads | `boolean` |         |          |        |
| `polish_medaka` | Polish assembly with medaka (ONT only)           | `boolean` |         |          |        |
| `medaka_model`  | model to use with medaka                         | `string`  | ""      |          |        |

## Scaffolding options

Scaffolding options

| Parameter             | Description                                | Type      | Default | Required | Hidden |
| --------------------- | ------------------------------------------ | --------- | ------- | -------- | ------ |
| `scaffold_longstitch` | Scaffold with longstitch?                  | `boolean` |         |          |        |
| `scaffold_links`      | Scaffolding with links?                    | `boolean` |         |          |        |
| `scaffold_ragtag`     | Scaffold with ragtag (requires reference)? | `boolean` |         |          |        |

## QC options

Options for QC tools

| Parameter          | Description                                                                                                                                         | Type      | Default           | Required | Hidden |
| ------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------- | --------- | ----------------- | -------- | ------ |
| `merqury`          | Run merqury (if short reads are provided)                                                                                                           | `boolean` | True              |          |        |
| `qc_reads`         | Long reads that should be used for QC when both ONT and HiFi reads are provided. Options are `'ont'` or `'hifi'`                                    | `string`  | ont               |          |        |
| `busco`            | Run BUSCO?                                                                                                                                          | `boolean` |                   |          |        |
| `busco_db`         | Path to busco db (optional)                                                                                                                         | `string`  |                   |          |        |
| `busco_lineage`    | Busco lineage to use                                                                                                                                | `string`  | brassicales_odb10 |          |        |
| `quast`            | Run quast                                                                                                                                           | `boolean` |                   |          |        |
| `ref_map_bam`      | A mapping (bam) of reads mapped to the reference can be provided for QC. If provided alignment to reference fasta will not run                      | `string`  |                   |          |        |
| `assembly`         | Can be used to proved existing assembly will skip assembly and perform downstream steps including qc                                                | `string`  |                   |          |        |
| `assembly_map_bam` | A mapping (bam) of reads mapped to the provided assembly can be specified for QC. If provided alignment to the provided assembly fasta will not run | `string`  |                   |          |        |

## Annotations options

Options controlling annotation liftover

| Parameter          | Description                               | Type      | Default | Required | Hidden |
| ------------------ | ----------------------------------------- | --------- | ------- | -------- | ------ |
| `lift_annotations` | Lift-over annotations (requires ref_gff)? | `boolean` | True    |          |        |

## Short read options

Options for short reads

| Parameter         | Description                     | Type      | Default | Required | Hidden |
| ----------------- | ------------------------------- | --------- | ------- | -------- | ------ |
| `use_short_reads` | Use short reads?                | `boolean` |         |          |        |
| `shortread_trim`  | Trim short reads?               | `boolean` |         |          |        |
| `meryl_k`         | kmer length for meryl / merqury | `integer` | 21      |          |        |
| `shortread_F`     | Path to forward short reads     | `string`  |         |          |        |
| `shortread_R`     | Path to reverse short reads     | `string`  |         |          |        |
| `paired`          | Are shortreads paired?          | `string`  |         |          |        |
