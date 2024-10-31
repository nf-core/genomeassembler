<h1>
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset="docs/images/nf-core-genomeassembler_logo_dark.png">
    <img alt="nf-core/genomeassembler" src="docs/images/nf-core-genomeassembler_logo_light.png">
  </picture>
</h1>

[![GitHub Actions CI Status](https://github.com/nf-core/genomeassembler/actions/workflows/ci.yml/badge.svg)](https://github.com/nf-core/genomeassembler/actions/workflows/ci.yml)
[![GitHub Actions Linting Status](https://github.com/nf-core/genomeassembler/actions/workflows/linting.yml/badge.svg)](https://github.com/nf-core/genomeassembler/actions/workflows/linting.yml)[![AWS CI](https://img.shields.io/badge/CI%20tests-full%20size-FF9900?labelColor=000000&logo=Amazon%20AWS)](https://nf-co.re/genomeassembler/results)[![Cite with Zenodo](http://img.shields.io/badge/DOI-10.5281/zenodo.XXXXXXX-1073c8?labelColor=000000)](https://doi.org/10.5281/zenodo.XXXXXXX)
[![nf-test](https://img.shields.io/badge/unit_tests-nf--test-337ab7.svg)](https://www.nf-test.com)

[![Nextflow](https://img.shields.io/badge/nextflow%20DSL2-%E2%89%A524.04.2-23aa62.svg)](https://www.nextflow.io/)
[![run with conda](http://img.shields.io/badge/run%20with-conda-3EB049?labelColor=000000&logo=anaconda)](https://docs.conda.io/en/latest/)
[![run with docker](https://img.shields.io/badge/run%20with-docker-0db7ed?labelColor=000000&logo=docker)](https://www.docker.com/)
[![run with singularity](https://img.shields.io/badge/run%20with-singularity-1d355c.svg?labelColor=000000)](https://sylabs.io/docs/)
[![Launch on Seqera Platform](https://img.shields.io/badge/Launch%20%F0%9F%9A%80-Seqera%20Platform-%234256e7)](https://cloud.seqera.io/launch?pipeline=https://github.com/nf-core/genomeassembler)

[![Get help on Slack](http://img.shields.io/badge/slack-nf--core%20%23genomeassembler-4A154B?labelColor=000000&logo=slack)](https://nfcore.slack.com/channels/genomeassembler)[![Follow on Twitter](http://img.shields.io/badge/twitter-%40nf__core-1DA1F2?labelColor=000000&logo=twitter)](https://twitter.com/nf_core)[![Follow on Mastodon](https://img.shields.io/badge/mastodon-nf__core-6364ff?labelColor=FFFFFF&logo=mastodon)](https://mstdn.science/@nf_core)[![Watch on YouTube](http://img.shields.io/badge/youtube-nf--core-FF0000?labelColor=000000&logo=youtube)](https://www.youtube.com/c/nf-core)

## Introduction

**nf-core/genomeassembler** is a bioinformatics pipeline that carries out genome assembly, polishing and scaffolding from long reads (ONT or pacbio). Assembly can be done via `flye` or `hifiasm`, polishing can be carried out with `medaka` (ONT), or `pilon` (requires short-reads), and scaffolding can be done using `LINKS`, `Longstitch`, or `RagTag` (if a reference is available). Quality control includes, BUSCO, QUAST and merqury (requires short-reads).
Currently, this pipeline does not implement phasing of polyploid genomes or HiC scaffolding. 

## Usage

> [!NOTE]
> If you are new to Nextflow and nf-core, please refer to [this page](https://nf-co.re/docs/usage/installation) on how to set-up Nextflow. Make sure to [test your setup](https://nf-co.re/docs/usage/introduction#how-to-run-a-pipeline) with `-profile test` before running the workflow on actual data.

First, prepare a samplesheet with your input data that looks as follows:

`samplesheet.csv`:

```csv
sample,ontreads,hifireads,ref_fasta,ref_gff,shortread_F,shortread_R,paired
sampleName,ontreads.fa.gz,hifireads.fa.gz,assembly.fasta.gz,reference.fasta,reference.gff,short_F1.fastq,short_F2.fastq,true
```

Each row represents one genome to be assembled. `sample` should contain the name of the sample, `ontreads` should contain a path to ONT reads (fastq.gz), `hifireads` a path to HiFi reads (fastq.gz), `ref_fasta` and `ref_gff` contain reference genome fasta and annotations. `shortread_F` and `shortread_R` contain paths to short-read data, `paired` indicates if short-reads are paired. Columns can be omitted if they contain no data, with the exception of `shortread_R`, which needs to be present if `shortread_F` is there, even if it is empty.

-->

Now, you can run the pipeline using:

<!-- TODO nf-core: update the following command to include all required parameters for a minimal example -->

```bash
nextflow run nf-core/genomeassembler \
   -profile <docker/singularity/.../institute> \
   --input samplesheet.csv \
   --outdir <OUTDIR>
```

> [!WARNING]
> Please provide pipeline parameters via the CLI or Nextflow `-params-file` option. Custom config files including those provided by the `-c` Nextflow option can be used to provide any configuration _**except for parameters**_; see [docs](https://nf-co.re/docs/usage/getting_started/configuration#custom-configuration-files).

For more details and further functionality, please refer to the [usage documentation](https://nf-co.re/genomeassembler/usage) and the [parameter documentation](https://nf-co.re/genomeassembler/parameters).

### Pipeline specific parameters

| Parameter | Description | Type | Default | Required | Hidden |                                                                                                                                                                                                        
|-----------|-----------|-----------|-----------|-----------|-----------|                                                                                                                                                                                               
| `ont` | ONT reads available? | `boolean` |  |  |  |                                                                                                                                                                                                                   
| `hifi` | HiFi reads available? | `boolean` |  |  |  |                                                                                                                                                                                                                 
| `short_reads` | Short reads available? | `boolean` |  |  |  |                                                                                                                                                                                                         
| `collect` | collect ONT reads into a single file | `boolean` |  |  |  |                                                                                                                                                                                               
| `porechop` | run porechop on ONT reads | `boolean` |  |  |  |                                                                                                                                                                                                         
| `lima` | run lima on HiFi reads? | `boolean` |  |  |  |                                                                                                                                                                                                               
| `pacbio_primers` | file containing pacbio primers for trimming with lima | `string` |  |  |  |                                                                                                                                                                        
| `trim_short_reads` | trim short reads with trimgalore | `boolean` |  |  |  |                                                                                                                                                                                          
| `assembler` | Assembler to use. Valid choices are: `'hifiasm'`, `'flye'`, or `'flye_on_hifiasm'`. `flye_on_hifiasm` will scaffold flye assembly (ont) on hifiasm (hifi) assembly using ragtag | `string` |  |  |  |                                                   
| `kmer_length` | kmer length to be used for jellyfish | `integer` |  |  |  |                                                                                                                                                                                           
| `read_length` | read length for genomescope (ONT only) | `string` |  |  |  |                                                                                                                                                                                          
| `dump` | dump jellyfish output | `boolean` |  |  |  |                                                                                                                                                                                                                 
| `meryl_k` | kmer length for meryl | `integer` |  |  |  |                                                                                                                                                                                                              
| `use_ref` | use reference genome | `boolean` |  |  |  |                                                                                                                                                                                                               
| `genome_size` | expected genome size | `string` |  |  |  |                                                                                                                                                                                                            
| `flye_mode` | flye mode | `string` | "--nano-hq" |  |  |                                                                                                                                                                                                              
| `flye_args` | additional args for flye | `string` | "" |  |  |                                                                                                                                                                                                        
| `qc_reads` | Long reads that should be used for QC when both ONT and HiFi reads are provided. Options are `'ONT'` or `'HIFI'` | `string` | "ONT" |  |  |                                                                                                              
| `hifiasm_ont` | Use hifi and ONT reads with `hifiasm --ul` | `boolean` |  |  |  |                                                                                                                                                                                     
| `hifiasm_args` | Extra arguments passed to `hifiasm` | `string` | "" |  |  |                                                                                                                                                                                          
| `polish_pilon` | Polish assembly with pilon? | `boolean` |  |  |  |                                                                                                                                                                                                   
| `polish_medaka` | Polish assembly with medaka (ONT only) | `boolean` |  |  |  |                                                                                                                                                                                       
| `medaka_model` | model to use with medaka | `string` | 'r1041_e82_400bps_hac_v4.2.0' |  |  |                                                                                                                                                                          
| `scaffold_ragtag` | Scaffold with ragtag (requires reference)? | `boolean` |  |  |  |                                                                                                                                                                                 
| `scaffold_links` | Scaffolding with links? | `boolean` |  |  |  |                                                                                                                                                                                                     
| `scaffold_longstitch` | Scaffold with longstitch? | `boolean` |  |  |  |                                                                                                                                                                                              
| `lift_annotations` | Lift-over annotations (requires reference)? | `boolean` |  |  |  |                                                                                                                                                                               
| `busco` | Run BUSCO? | `boolean` |  |  |  |                                                                                                                                                                                                                           
| `busoc_db` | Path to busco db | `string` | '' |  |  |                                                                                                                                                                                                                 
| `busco_lineage` | Busco lineage to use | `string` | "brassicales_odb10" |  |  |                                                                                                                                                                                       
| `quast` | Run quast | `boolean` |  |  |  |                                                                                                                                                                                                                            
| `skip_assembly` | skip assembly steps <details><summary>Help</summary><small>Skip assembly and perform only qc.</small></details>| `boolean` |  |  |  |                                                                                                               
| `skip_alignments` | skip alignments during qc | `boolean` |  |  |  |                                                                                                                                                                                                  
| `jellyfish` | run jellyfish and genomescope on ONT reads to compute k-mer distribution and estimate genome size | `boolean` |  |  |  |                                                                                                                                                
| `yak` | run qc via yak | `boolean` |  |  |  |                                                                                                                                                                                                                         
                                                                                                                                                                                                                                                                        




## Pipeline output

To see the results of an example test run with a full size dataset refer to the [results](https://nf-co.re/genomeassembler/results) tab on the nf-core website pipeline page.
For more details about the output files and reports, please refer to the
[output documentation](https://nf-co.re/genomeassembler/output).

## Credits

nf-core/genomeassembler was originally written by Niklas Schandry.

We thank the following people for their extensive assistance in the development of this pipeline:

<!-- TODO nf-core: If applicable, make list of people who have also contributed -->

## Contributions and Support

If you would like to contribute to this pipeline, please see the [contributing guidelines](.github/CONTRIBUTING.md).

For further information or help, don't hesitate to get in touch on the [Slack `#genomeassembler` channel](https://nfcore.slack.com/channels/genomeassembler) (you can join with [this invite](https://nf-co.re/join/slack)).

## Citations

<!-- TODO nf-core: Add citation for pipeline after first release. Uncomment lines below and update Zenodo doi and badge at the top of this file. -->
<!-- If you use nf-core/genomeassembler for your analysis, please cite it using the following doi: [10.5281/zenodo.XXXXXX](https://doi.org/10.5281/zenodo.XXXXXX) -->

<!-- TODO nf-core: Add bibliography of tools and data used in your pipeline -->

An extensive list of references for the tools used by the pipeline can be found in the [`CITATIONS.md`](CITATIONS.md) file.

You can cite the `nf-core` publication as follows:

> **The nf-core framework for community-curated bioinformatics pipelines.**
>
> Philip Ewels, Alexander Peltzer, Sven Fillinger, Harshil Patel, Johannes Alneberg, Andreas Wilm, Maxime Ulysse Garcia, Paolo Di Tommaso & Sven Nahnsen.
>
> _Nat Biotechnol._ 2020 Feb 13. doi: [10.1038/s41587-020-0439-x](https://dx.doi.org/10.1038/s41587-020-0439-x).
