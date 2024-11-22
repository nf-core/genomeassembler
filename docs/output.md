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
    - `jellyfish/`
      - `count/`
        - `<SampleName>/`: output from jellyfish count
      - `stats/`
        - `<SampleName>/`: output from jellyfish stats
      - `histo/`
        - `<SampleName>/`: output from jellyfish histogram
      - `dump/`
        - `<SampleName>/`: output from jellyfish dump
    - `genomescope/`
      - `<SampleName>/`: genomescope plots

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
  - `trimgalore/`:
    - `<SampleName>_val_1.fq.gz`: Trimmed forward reads
    - `<SampleName>_val_2.fq.gz`: Trimmed reverse reads (if included)
    - `<SampleName>_1.fastq.gz.trimming_report.txt`: Trimming report forward
    - `<SampleName>_2.fastq.gz.trimming_report.txt`: Trimming report reverse (if included)
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

</details>

### Polishing

Polishing can be used to correct errors in the assembly.

<details markdown="1">
<summary>Output files</summary>

- `polish/`
  - `pilon/`: output from pilon
  - `medaka/`: output from medaka

</details>

### Scaffolding

The initial assembly can be scaffolded using different tools.

<details markdown="1">
<summary>Output files</summary>

- `scaffold/`
  - `links/`: output from links
  - `longstitch/`: output from longstitch
  - `ragtag/`: output from RagTag
  - `liftoff`: outputs from the annotation liftover via liftoff

</details>

### Annotations

If a reference is provided, and annotation liftover is desired, liftoff will lift-over annotations at each stage of the assembly.

<details markdown="1">
<summary>Output files</summary>

- `assemble/` | `polish/<tool>/` | `scaffold/<tool>/`:
  - `liftoff/`: - `<SampleName>/`: - `<SampleName>.<suffix>_liftoff.gff` gff file produced by liftoff. Exact name depends on the stage of the pipeline.
  </summary>

### Quality control

All quality control files end up in `QC`. Below is the tree assuming that all steps of the pipeline were run

<details markdown="1">
<summary>Output folders</summary>

- `QC/`
  - `assemble/`: qc after the initial assembly
  - `polish/`:
    - `pilon/`: qc after polishing with pilon
    - `medaka/`: qc after polishing with medaka
  - `scaffold`: qc of scaffolding - `links`: qc after scaffolding with links - `longstitch`: qc after scaffolding with longstitch - `ragtag`: qc after scaffolding with ragtag
  </details>

For each step, `BUSCO`,`QUAST`, and `merqury` can be used for QC.

<details markdown="1">
<summary>Folder contents</summary>

- `busco`: BUSCO analysis of the assembly
  - `<SampleName>`
- `quast`: QUAST analysis of the assembly, per sample, contains:
  - `<Sample Name>`:
    - `map_to_ref` and `map_to_assembly`: mapping of long reads to the reference and assembly respectively. `map_to_ref` is only performed once, during the first run of QUAST, typically in `assemble`
      - `align/`: Alignment of long reads to the genome in ` format
        - `<FastaFile>.bam`: Alignment of long reads to the genome
      - `samtools/`:
        - `<FastaFile>.bam.bai`: bam index
        - `<FastaFile>.bam.idxstats`: samtools idxstats
        - `<FastaFile>.bam.flagstat`: samtools flagstats
        - `<FastaFile>.bam.stats`: samtools stats
- `merqury`: merqury analysis of the assembly
  - `<SampleName>`:
    - `<FastaFile>.<SampleName>.assembly.qv`: QV of the assembly (per sequence)
    - `<FastaFile>.<SampleName>.assembly.spectra-cn.fl.png` : Copy Number plot, filled
    - `<FastaFile>.<SampleName>.assembly.spectra-cn.ln.png` : Copy Number plot, lines
    - `<FastaFile>.<SampleName>.assembly.spectra-cn.st.png` : Copy Number plot, semi-transparent
    - `<FastaFile>.<SampleName>.assembly.spectra-cn.hist` : Copy Number histogram file
    - `<FastaFile>.completeness.stats` : Assembly completeness statistics (overall)
    - `<FastaFile>.qv` : Assembly QV (overall)
    - `<FastaFile>.spectra-asm.fl.png` : Assembly k-mer spectrum, filled
    - `<FastaFile>.spectra-asm.ln.png` : Assembly k-mer spectrum, lines
    - `<FastaFile>.spectra-asm.st.png` : Assembly k-mer spectrum, semi-transparent
    - `<FastaFile>.spectra-asm.hist` : Assembly QV (overall)
    - `<FastaFile>.dist_only.hist` : Number of k-mers distinct to the assembly
    - `<SampleName>.assembly_only.bed` : bp errors in assembly (bed)
    - `<SampleName>.assembly_only.wig` : bp errors in assembly (wig)
    - `<SampleName>.unionsum.hist.ploidy` : ploidy estimates from short-reads

</details>

### Report

The pipeline collects the quality control outputs into an html report. Below is the tree assuming that all steps of the pipeline were run:

<details markdown="1">
<summary>Output files</summary>
    
  - `report/`:
    - `busco_files/reports.tsv`: Table containing aggregated BUSCO reports
    - `quast_files/reports.tsv`: Table containing aggregated QUAST reports
    - `report.html` : The report file.
    - `report_files/`: Folder containing js and css. required to properly display the `.html` file

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
