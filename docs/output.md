# nf-core/genomeassembler: Output

## Introduction

This document describes the output produced by the pipeline..

The directories listed below will be created in the results directory after the pipeline has finished. All paths are relative to the top-level results directory.

<!-- TODO nf-core: Write this documentation describing your workflow's output -->

## Pipeline overview

The pipeline is built using [Nextflow](https://www.nextflow.io/) and processes data using the following steps:

- Read preparation
  - **ONT Reads**:
    - `collect` into single fastq file
    - `porechop` to remove adaptors
    - `nanoq` for statistics
    - `jellyfish` / `genomescope` genome size estimate based on k-mer spectrum
  - **HiFi reads**:
    - `lima`
  - **Short reads**:
    - `trimgalore`
- **Assembly**, choice between assemblers
  - `flye` for ONT or HiFi reads
  - `hifiasm` for HiFi reads or ONT+HiFi reads
- **Polishing**
  - `medaka` for ONT reads
  - `pilon` for short reads
- **Scaffolding**
  - `LINKS` for scaffolding based on long-reads
  - `longstitch` scaffolding based on long-reads
  - `RagTag` scaffolding on reference
- **Annotation liftover**
  - `liftoff`
- **Quality control**
  - `QUAST`, assembly statistics, can incorporate reference
  - `BUSCO`, assembly completeness based on expected single copy ortholgos
  - `merqury`, various assembly measures, compares k-mer between short reads and assembly
- **Reporting**
  - html dashboard

## Output structure

Annotation and quality control are done at several stages of the pipeline, the output is organized by subworkflow, corresponding to the bolded steps above.

/!\ This is still work in progress

### ONT reads

<details markdown="1">
<summary>Output files</summary>

- `ont_reads/`
  - `collect/`: single fastq.gz files per sample
  - `porechop/`: output from porechop, fastq.gz
  - `nanoq/`: output from nanoq
  - `genomescope/`: output from jellyfish and genomescope
    - `jellyfish/`: output from jellyfish
      - `count/`: output from jellyfish count
      - `stats/`: output from jellyfish stats
      - `histo/`: output from jellyfish histogram
      - `dump/`: output from jellyfish dump
    - `genomescope/`: genomescope

</details>

### HiFi reads

<details markdown="1">
<summary>Output files</summary>

- `hifi_reads/`
  - `lima/`: hifi reads after adaptor removal with lima

</details>

### Short reads

<details markdown="1">
<summary>Output files</summary>

- `short_reads/`
  - `trimgalore/`: trimmed short reads
  - `meryl/`: output from meryl
    - `count/`: k-mer counts per file
    - `unionsum/`: union of k-mer counts per sample

</details>

### Assembly

This folder contains the initial assemblies of the provided reads.

<details markdown="1">
<summary>Output files</summary>

- `assemble/`
  - `flye/`: output from flye.
    - `<SampleName>/`
      - `<SampleName>.assembly.fasta.gz`: Assembly in gzipped fasta format
      - `<SampleName>.assembly_graph.gfa.gz`: Assembly graph in gzipped gfa format
      - `<SampleName>.assembly_graph.gv.gz`: Assembly graph in gzipped gv format
      - `<SampleName>.assembly_info.txt`: Information on the assembly
      - `<SampleName>.flye.log`: flye log-file
      - `<SampleName>.params.json`: params used for running flye
  - `hifiasm/`: output from hifiasm. Contains one folder per sample
    - `<SampleName>`
      - `<SampleName>.asm.bp.p_ctg.fa.gz`: gzipped fasta file of the primary contigs
      - `<SampleName>.asm.bp.p_ctg.gfa`: primary contigs in gfa format
      - `<SampleName>.asm.bp.p_utg.gfa`: processed unitigs in gfa format
      - `<SampleName>.asm.bp.r_utg.gfa`: raw unitigs in gfa format
      - `<SampleName>.stderr.log`: Any output form hifiasm to stderr
  - `ragtag/`: output from RagTag, only if `'flye_on_hifiasm'` was used as the assembler. Contains one folder per sample.
    - `<SampleName>`
      - `<SampleName>.assembly.fasta.gz_on_<SampleName>.asm.bp.p_ctg.fa.gz/`
        - `<SampleName>.assembly.fasta.gz_ragtag_<SampleName>.asm.bp.p_ctg.fa.gz.agp`: Scaffolds in agp format
        - `<SampleName>.assembly.fasta.gz_ragtag_<SampleName>.asm.bp.p_ctg.fa.gz.fasta`: Scaffolds in fasta format
        - `<SampleName>.assembly.fasta.gz_ragtag_<SampleName>.asm.bp.p_ctg.fa.gz.stats`: Scaffolding statistics.
  - `liftoff/`: outputs from the annotation liftover via liftoff, requires reference.
    - `<SampleName>/`
      - `<SampleName>.<suffix>_liftoff.gff` gff file produced by liftoff. Exact name depends on the assembler used. `<suffix>` is `assembly.fasta.gz` for flye assemblies and `asm.bp.p_ctg.fa.gz` for hifiasm assemblies.

</details>

### Polishing

Polishing can be used to correct errors in the assembly.

### Scaffolding

The initial assembly can be scaffolded using different tools.

<details markdown="1">
<summary>Output files</summary>

- `scaffold/`
  - `links/`: output from links
  - `longstitch/`: output from longstitch
  - `ragtag/`: output from RagTag
  - `liftoff`: outputs from the annotation liftover via liftoff, requires reference

</details>

### Quality control

All quality control files end up in `QC`.

<details markdown="1">
<summary>Output files</summary>

- `QC/`
  - `assemble/`: qc of the initiall assembly
    - `busco`: BUSCO analysis of the assembly, per sample
    - `quast`: QUAST analysis of the assembly, per sample, contains:
      - `<Sample Name>`:
        - `map_to_ref`: mapping of long reads to the reference
        - `map_to_assembly`: mapping of long reads to assembly
    - `merqury`: merqury analysis of the assembly, per sample.
  - `longstitch/`: output from longstitch
  - `ragtag/`: output from RagTag
  - `liftoff`: outputs from the annotation liftover via liftoff, requires reference

</details>

### Pipeline information

<details markdown="1">
<summary>Output files</summary>

- `pipeline_info/`
  - Reports generated by Nextflow: `execution_report.html`, `execution_timeline.html`, `execution_trace.txt` and `pipeline_dag.dot`/`pipeline_dag.svg`.
  - Reports generated by the pipeline: `pipeline_report.html`, `pipeline_report.txt` and `software_versions.yml`. The `pipeline_report*` files will only be present if the `--email` / `--email_on_fail` parameter's are used when running the pipeline.
  - Reformatted samplesheet files used as input to the pipeline: `samplesheet.valid.csv`.
  - Parameters used by the pipeline run: `params.json`.

</details>

[Nextflow](https://www.nextflow.io/docs/latest/tracing.html) provides excellent functionality for generating various reports relevant to the running and execution of the pipeline. This will allow you to troubleshoot errors with the running of the pipeline, and also provide you with other information such as launch commands, run times and resource usage.
