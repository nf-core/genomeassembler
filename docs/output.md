# nf-core/genomeassembler: Output

## Introduction

This document describes the output produced by the pipeline.

The directories listed below will be created in the results directory after the pipeline has finished. All paths are relative to the top-level results directory.

## Pipeline overview

The pipeline is built using [Nextflow](https://www.nextflow.io/) and processes data using the following steps:

- [**Read preparation**](#read-preparation)
  - [**Long reads**](#long-reads):
  - [**Short reads**](#short-reads):
- [**Assembly**](#assembly), choice between assemblers
- [**Polishing**](#polishing)
- [**Scaffolding**](#scaffolding)
- [**Annotation liftover**](#annotations)
- [**Quality control**](#quality-control)
- [**Reporting**](#report)

## Output structure

Outputs are collect into the output directory by sample:

<details markdown="1">
<summary>Output files</summary>

- `<SampleName>/`

</details>

Within each sample, the files are structured as follows:

### Read preparation

The outputs from all read preparation steps are emitted into `<SampleName>/reads/`.

#### Long reads

If the ONT basecalls are scattered across multiple files, `collect` can be used to collect those into a single file.
[fastplong](https://github.com/OpenGene/fastplong) is a tool for QC and preprocessing of long-reads.
[genomescope](https://github.com/tbenavi1/genomescope2.0) estimates genome size and ploidy from the k-mer spectrum computed by [jellyfish](https://github.com/gmarcais/Jellyfish).

<details markdown="1">
<summary>Output files</summary>

- `<SampleName>/`
  - `reads/`
    - `collect/`: single fastq.gz files per sample
    - `fastplong/`: output from fastplong, fastq.gz and report in json and html format.
      - `ont/`: fastplong output for ONT reads
      - `hifi/`: fastplong output for HiFi reads
    - `genomescope/`: output from jellyfish and genomescope
      - `jellyfish/`
        - `count/`: output from jellyfish count
        - `stats/`: output from jellyfish stats
        - `histo/`: output from jellyfish histogram
        - `dump/`: output from jellyfish dump
      - `genomescope/`: genomescope plots

</details>

#### Short reads

[TrimGalore!](https://github.com/FelixKrueger/TrimGalore) can remove adapters from illumina short-reads.
[meryl](https://github.com/marbl/meryl) calculates the k-mer spectrum of short reads.

<details markdown="1">
<summary>Output files</summary>

- `<SampleName>/`
  - `reads/`
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
Depending on the assembly strategy chosen, different assemblers are used.
[flye](https://github.com/mikolmogorov/Flye) performs assembly of ONT reads
[hifiasm](https://github.com/chhylp123/hifiasm) performs assembly of HiFi or ONT reads, or combinations of HiFi reads and ONT reads in `--ul` mode.
[ragtag](https://github.com/malonge/RagTag) performs scaffolding and can be used to scaffold assemblies of ONT onto assemblies of HiFi reads.
Annotation `gff3` and `unmapped.txt` files are only created if a reference for annotation liftover is provided and `lift_annotations` is enabled.

<details markdown="1">
<summary>Output files</summary>

- `<SampleName>`
  - `assembly/`
    - `flye/`: output from flye.
      - `<SampleName>.assembly.fasta.gz`: Assembly in gzipped fasta format
      - `<SampleName>.assembly_graph.gfa.gz`: Assembly graph in gzipped gfa format
      - `<SampleName>.assembly_graph.gv.gz`: Assembly graph in gzipped gv format
      - `<SampleName>.assembly_info.txt`: Information on the assembly
      - `<SampleName>.flye.log`: flye log-file
      - `<SampleName>.params.json`: params used for running flye
    - `hifiasm/`: output from hifiasm.
      - `<SampleName>.asm.bp.p_ctg.fa.gz`: gzipped fasta file of the primary contigs
      - `<SampleName>.asm.bp.p_ctg.gfa`: primary contigs in gfa format
      - `<SampleName>.asm.bp.p_utg.gfa`: processed unitigs in gfa format
      - `<SampleName>.asm.bp.r_utg.gfa`: raw unitigs in gfa format
      - `<SampleName>.stderr.log`: Any output form hifiasm to stderr
      - `gfa2_fasta/`: hifiasm assembly in fasta format.
    - `ragtag/`: output from RagTag, only if `'scaffold'` was used as the strategy.
      - `<SampleName>_assembly_scaffold/`
        - `<SampleName>_assembly_scaffold.agp`: Scaffolds in agp format
        - `<SampleName>_assembly_scaffold.fasta`: Scaffolds in fasta format
        - `<SampleName>_assembly_scaffold.stats`: Scaffolding statistics.
    - `<SampleName>_assembly.gff3` annotation liftover
    - `<SampleName>_assembly.unnapped.txt` annotations that could not be lifted over during annotation liftover

</details>

### Polishing

Polishing can be used to correct errors in the assembly. This pipeline supports two polishing tools.
[medaka](https://github.com/nanoporetech/medaka/) polishes assemblies using the ONT reads that were used for assembly.
[pilon](https://github.com/broadinstitute/pilon) polishes any type of assembly using short-reads.
Annotation `gff3` and `unmapped.txt` files are only created if a reference for annotation liftover is provided and `lift_annotations` is enabled.

<details markdown="1">
<summary>Output files</summary>

- `<SampleName>`
  - `polish/`
    - `pilon/`: output from pilon
      - `<SampleName>_pilon.fasta` Polished assembly
      - `<SampleName>_pilon.gff3` annotation liftover
      - `<SampleName>_pilon.unnapped.txt` annotations that could not be lifted over during annotation liftover
    - `medaka/`: output from medaka
      - `<SampleName>_medaka.fa.gz` Polished assembly
      - `<SampleName>_medaka.gff3` annotation liftover
      - `<SampleName>_medaka.unnapped.txt` annotations that could not be lifted over during annotation liftover

</details>

### Scaffolding

The (polished) assembly can be scaffolded using different tools.
[links](https://github.com/bcgsc/LINKS) performs scaffolding of the assembly using long-reads
[longstitch](https://github.com/bcgsc/longstitch) performs correction via [Tigmint](https://github.com/bcgsc/tigmint) and scaffolding using long reads via [ntLink](https://github.com/bcgsc/ntLink) and [ARKS](https://github.com/bcgsc/arcs).
Annotation `gff3` and `unmapped.txt` files are only created if a reference for annotation liftover is provided and `lift_annotations` is enabled.

<details markdown="1">
<summary>Output files</summary>

- `<SampleName>`
  - `scaffold/`
    - `links/`: output from links
      - `<SampleName>_links.gv`: scaffolding graph
      - `<SampleName>_links.log`: log file
      - `<SampleName>_links.scaffolds`: scaffold statistics
      - `<SampleName>_links.scaffolds.fa`: scaffold fasta
      - `<SampleName>_links.gff3` annotation liftover
      - `<SampleName>_links.unnapped.txt` annotations that could not be lifted over during annotation liftover
    - `longstitch/`: output from longstitch
      - `<SampleName>_tigmint-ntLinks.arks.longstitch-scaffolds.fa`: Scaffolds after scaffolding with tigmint, ntLinks, and arks. Annotations are based on this file.
      - `<SampleName>_tigmint-ntLinks.longstitch-scaffolds.fa`: Scaffolds after scaffolding with tigmint, and ntLinks.
      - `<SampleName>_longstitch.gff3` annotation liftover (onto `*._tigmint-ntLinks.arks.*`)
      - `<SampleName>_longstitch.unnapped.txt` annotations that could not be lifted over during annotation liftover
    - `ragtag/`: output from RagTag
      - `<SampleName>_ragtag_<Reference>/`
        - `<SampleName>_ragtag_<Reference>.agp`: agp file, scaffolding results
        - `<SampleName>_ragtag_<Reference>.fasta`: Scaffold fasta file
        - `<SampleName>_ragtag_<Reference>.stats`: Scaffolding statistics
        - `<SampleName>_ragtag.gff3` annotation liftover
        - `<SampleName>_ragtag.unnapped.txt` annotations that could not be lifted over during annotation liftover

</details>

### Quality control

All quality control files end up in `QC`. Below is the tree assuming that all steps of the pipeline were run:

- [`nanoq`](https://github.com/esteinig/nanoq) generates descriptive statistics of the nanopore reads.
  For each step three quality control tools can be run.
- [`QUAST`](https://github.com/ablab/quast) provides assembly statistics (e.g. size, N50, etc. )
- [`BUSCO`](https://busco.ezlab.org/) assess genome quality based on the presence of lineage-specific single-copy orthologs
- [`merqury`](https://github.com/marbl/merqury) compares the genome k-mer spectrum to the short-read k-mer spectrum to assess base-accuracy of the assembly.

The files and folders in the different QC folders are named based on
`<SampleName>` and `<stage>`. SampleName is the sample name, and stage is one of: `assembly`, `medaka`, `pilon`, `links`, `longstitch` or `ragtag`.

<details markdown="1">
<summary>Folder contents</summary>

- `<SampleName>`
  - `QC/`:
    - `BUSCO/`: BUSCO reports
      - `<SampleName>_<stage>-<BuscoLineage>-busco/`: BUSCO output folder, please refer to BUSCO documentation for details.
      - `<SampleName>_<stage>-<BuscoLineage>-busco.batch_summary.txt`: BUSCO batch summary output
      - `short_summary.specific.<SampleName>_<stage>.{txt,json}`: BUSCO short summaries in txt and json format
    - `merqury/`: merqury analysis of the assembly
      - `<SampleName>_<stage>.<SampleName>.assembly.qv`: QV of the assembly (per sequence)
      - `<SampleName>_<stage>.<SampleName>.assembly.spectra-cn.fl.png` : Copy Number plot, filled
      - `<SampleName>_<stage>.<SampleName>.assembly.spectra-cn.ln.png` : Copy Number plot, lines
      - `<SampleName>_<stage>.<SampleName>.assembly.spectra-cn.st.png` : Copy Number plot, semi-transparent
      - `<SampleName>_<stage>.<SampleName>.assembly.spectra-cn.hist` : Copy Number histogram file
      - `<SampleName>_<stage>.completeness.stats` : Assembly completeness statistics (overall)
      - `<SampleName>_<stage>.qv` : Assembly QV (overall)
      - `<SampleName>_<stage>.spectra-asm.fl.png` : Assembly k-mer spectrum, filled
      - `<SampleName>_<stage>.spectra-asm.ln.png` : Assembly k-mer spectrum, lines
      - `<SampleName>_<stage>.spectra-asm.st.png` : Assembly k-mer spectrum, semi-transparent
      - `<SampleName>_<stage>.spectra-asm.hist` : Assembly QV (overall)
      - `<SampleName>_<stage>.dist_only.hist` : Number of k-mers distinct to the assembly
      - `<SampleName>_<stage>.assembly_only.bed` : bp errors in assembly (bed)
      - `<SampleName>_<stage>.assembly_only.wig` : bp errors in assembly (wig)
      - `<SampleName>_<stage>.unionsum.hist.ploidy` : ploidy estimates from short-reads
    - `QUAST/`: QUAST analysis
      - `<Sample Name>_<stage>/`: QUAST results, cp. [QUAST Docs](https://github.com/ablab/quast?tab=readme-ov-file#output)
        - `report.txt`: summary table
        - `report.tsv`: tab-separated version, for parsing, or for spreadsheets (Google Docs, Excel, etc)
        - `report.tex`: Latex version
        - `report.pdf`: PDF version, includes all tables and plots for some statistics
        - `report.html`: everything in an interactive HTML file
        - `icarus.html`: Icarus main menu with links to interactive viewers
        - `contigs_reports/`: [only if a reference genome is provided]
          - `misassemblies_report`: detailed report on misassemblies
          - `unaligned_report`: detailed report on unaligned and partially unaligned contigs
        - `reads_stats/`: [only if reads are provided]
          - `reads_report`: detailed report on mapped reads statistics
      - `<Sample Name>_<stage_report>.tsv`: QUAST summary report

</details>

#### Alignments

All alignments created are saved to the results directory.

Alignments are created for:

- pilon: short read alignment
- QUAST:
  - long reads against reference (if provided)
  - long reads against assemblies / polishs / scaffolds

The files in the alignment folder have the following base name structure:
`<SampleName>_<stage>`. SampleName is the sample name, and stage is one of:
`assembly`, `medaka`, `pilon`, `links`, `longstitch` or `ragtag`.

<details markdown="1">
<summary>Output files</summary>

- `<SampleName>`
  - `QC/`
    - `alignments/`: alignments to assemblies
      - `<SampleName>_<stage>.bam` Alignment
      - `<SampleName>_<stage>.bai` bam index file
      - `<SampleName>_<stage>.stats` comprehensive statistics from alignment file
      - `<SampleName>_<stage>.idxstats` alignment summary statistics
      - `<SampleName>_<stage>.flagstat` number of alignments for each FLAG type
      - `shortreads/`: folder containing short read mapping for pilon
        - `<SampleName>_shortreads.bam` Alignment
        - `<SampleName>_shortreads.bai` bam index file
        - `<SampleName>_shortreads.stats` comprehensive statistics from alignment file
        - `<SampleName>_shortreads.idxstats` alignment summary statistics
        - `<SampleName>_shortreads.flagstat` number of alignments for each FLAG type
      - `reference/`: folder containing alignment of long reads to reference
        - `<SampleName>_to_reference.bam` Alignment
        - `<SampleName>_to_reference.bai` bam index file
        - `<SampleName>_to_reference.stats` comprehensive statistics from alignment file
        - `<SampleName>_to_reference.idxstats` alignment summary statistics
        - `<SampleName>_to_reference.flagstat` number of alignments for each FLAG type

</details>

### Report

The pipeline collects the quality control outputs into an html report. Below is the tree assuming that all steps of the pipeline were run:

<details markdown="1">
<summary>Output files</summary>

- `report/`:
  - `busco_files/reports.tsv`: Table containing aggregated BUSCO reports
  - `quast_files/reports.tsv`: Table containing aggregated QUAST reports
  - `report.html` : The report file
  - `report_files/`: Folder containing js and css. Required to properly display the `.html` file

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
