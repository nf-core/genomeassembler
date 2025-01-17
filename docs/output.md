# nf-core/genomeassembler: Output

## Introduction

This document describes the output produced by the pipeline..

The directories listed below will be created in the results directory after the pipeline has finished. All paths are relative to the top-level results directory.

## Pipeline overview

The pipeline is built using [Nextflow](https://www.nextflow.io/) and processes data using the following steps:

- [**Read preparation**](#read-preparation)
  - [**ONT Reads**](#ont-reads):
  - [**HiFi reads**](#hifi-reads):
  - [**Short reads**](#short-reads):
- [**Assembly**](#assembly), choice between assemblers
- [**Polishing**](#polishing)
- [**Scaffolding**](#scaffolding)
- [**Annotation liftover**](#annotations)
- [**Quality control**](#quality-control)
- [**Reporting**](#report)

## Output structure

Annotation and quality control are done at several stages of the pipeline, the output is organized by subworkflow, corresponding to the bolded steps above.

### Read preparation

#### ONT reads

If the basecalls are scattered across multiple files, `collect` can be used to collect those into a single file.
[porechop](https://github.com/rrwick/Porechop) is a tool that identifies and trims adapter sequences from ONT reads.
[nanoq](https://github.com/esteinig/nanoq) generates descriptive statistics of the nanopore reads.
[genomescope](https://github.com/tbenavi1/genomescope2.0) estimates genome size and ploidy from the k-mer spectrum computed by [jellyfish](https://github.com/gmarcais/Jellyfish).

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

#### HiFi reads

[lima](https://lima.how/) performs trimming of adapters from pacbio HiFi reads.

<details markdown="1">
<summary>Output files</summary>

- `hifi_reads/`
  - `lima/`: hifi reads after adapter removal with lima

</details>

#### Short reads

[TrimGalore!](https://github.com/FelixKrueger/TrimGalore) can remove adapters from illumina short-reads.
[meryl](https://github.com/marbl/meryl) calculates the k-mer spectrum of short reads.

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
Depending on the assembly strategy chosen, different assemblers are used.
[flye](https://github.com/mikolmogorov/Flye) performs assembly of ONT reads
[hifiasm](https://github.com/chhylp123/hifiasm) performs assembly of HiFi reads, or combinations of HiFi reads and ONT reads in `--ul` mode.
[ragtag](https://github.com/malonge/RagTag) performs scaffolding and can be used to scaffold assemblies of ONT onto assemblies of HiFi reads

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

Polishing can be used to correct errors in the assembly. This pipeline supports two polishing tools.
[medaka](https://github.com/nanoporetech/medaka/) polishes assemblies using the ONT reads that were used for assembly.
[pilon](https://github.com/broadinstitute/pilon) polishes any type of assembly using short-reads.

<details markdown="1">
<summary>Output files</summary>

- `polish/`
  - `pilon/`: output from pilon
  - `medaka/`: output from medaka

</details>

### Scaffolding

The (polished) assembly can be scaffolded using different tools.
[links](https://github.com/bcgsc/LINKS) performs scaffolding of the assembly using long-reads
[longstitch](https://github.com/bcgsc/longstitch) performs correction via [Tigmint](https://github.com/bcgsc/tigmint) and scaffolding using long reads via [ntLink](https://github.com/bcgsc/ntLink) and [ARKS](https://github.com/bcgsc/arcs)

<details markdown="1">
<summary>Output files</summary>

- `scaffold/`
  - `links/`: output from links
    - `<SampleName>/`:
      - `<SampleName>_links.gv`: scaffolding graph
      - `<SampleName>_links.log`: log file
      - `<SampleName>_links.scaffolds`: scaffold statistics
      - `<SampleName>_links.scaffolds.fa`: scaffold fasta
  - `longstitch/`: output from longstitch
    - `<SampleName>/`:
      - `<SampleName>_tigmint-ntLinks.arks.longstitch-scaffolds.fa`: Scaffolds after scaffolding with tigmint, ntLinks, and arks
      - `<SampleName>_tigmint-ntLinks.longstitch-scaffolds.fa`: Scaffolds after scaffolding with tigmint, and ntLinks
  - `ragtag/`: output from RagTag
    - `<SampleName>/`:
      - `<SampleName><suffix>_ragtag_<Reference>/`
        - `<SampleName><suffix>_ragtag_<Reference>.agp`: agp file, scaffolding results
        - `<SampleName><suffix>_ragtag_<Reference>.fasta`: Scaffold fasta file
        - `<SampleName><suffix>_ragtag_<Reference>.stats`: Scaffolding statistics

</details>

### Annotations

If a reference is provided, and annotation liftover is desired, the pipeline will lift-over annotations at each stage of the assembly.
[liftoff](https://github.com/agshumate/Liftoff) performs lift-over of annotations from a closely related species / individual.

<details markdown="1">
<summary>Output files</summary>

- `assemble/<SampleName>` | `polish/<tool>/<SampleName>` | `scaffold/<tool>/<SampleName>`:
  - `liftoff/`:
  - `<SampleName>.<suffix>_liftoff.gff` gff file produced by liftoff. Exact name depends on the stage of the pipeline.
    </summary>
  </details>

### Quality control

All quality control files end up in `QC`. Below is the tree assuming that all steps of the pipeline were run

For each step three quality control tools can be run.
[`QUAST`](https://github.com/ablab/quast) provides assembly statistics (e.g. size, N50, etc. )
[`BUSCO`](https://busco.ezlab.org/) assess genome quality based on the presence of lineage-specific single-copy orthologs
[`merqury`](https://github.com/marbl/merqury) compares the genome k-mer spectrum to the short-read k-mer spectrum to assess base-accuracy of the assembly.

<details markdown="1">
<summary>Folder contents</summary>

- `busco`: BUSCO analysis of the assembly
  - `<SampleName>/`:
    - `<SampleName>-<Stage>-<BuscoLineage>-busco/`: BUSCO output folder, please refer to BUSCO documentation for details.
    - `<SampleName>-<Stage>-<BuscoLineage>-busco.batch_summary.txt`: BUSCO batch summary output
    - `short_summary.specific.<FastaFile>.{txt,json}`: BUSCO short summaries in txt and json format
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
    - `<Sample Name>_<stage_report.tsv>`: QUAST summary report
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

<details markdown="1">
<summary>Output folders</summary>

- `QC/`
  - `assemble/`: qc after the initial assembly
  - `polish/`:
    - `pilon/`: qc after polishing with pilon
    - `medaka/`: qc after polishing with medaka
  - `scaffold`: qc of scaffolding
    - `links`: qc after scaffolding with links
    - `longstitch`: qc after scaffolding with longstitch
    - `ragtag`: qc after scaffolding with ragtag
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
