[![DOI](https://zenodo.org/badge/786746077.svg)](https://zenodo.org/doi/10.5281/zenodo.10972895)

The goal of [`nf-arassembly`](https://github.com/nschan/nf-arassembly) and [`nf-annotate`](https://github.com/nschan/nf-annotate) is to make to genome assembly and annotation workflows accessible for a broader community, particularily for plant-sciences. Long-read sequencing technologies are already cheap and will continue to drop in price, genome sequencing will soon be available to many researchers without a strong bioinformatic background. 
The assembly is naturally quite organisms agnostic, but the annotation pipeline contains some steps that may not make sense for other eukaryotes, unless there is a particular interest in NB-LRR genes.

# nf-arassembly

Assembly pipeline for arabidopsis genomes from long-read sequencing written in [`nextflow`](https://nextflow.io/). Should also work for other species.
The default expectation of this pipeline are ONT reads, however there is [support](#Usage-with-PacBio-reads), for pacbio HiFI and for combinations of ONT and pacbio HiFi data.

# Procedure

Preprocessisng:
  - For nanopore:
    * Extract all fastq.gz files in the readpath folder into a single fastq file. By default this is skipped, enable with `--collect`.
    * Barcodes and adaptors will be removed using [`porechop`](https://github.com/rrwick/Porechop). By default this is skipped, enable with `--porechop`.
      > NB: flye claims to work well on raw, un-trimmed reads
    * Read QC is done via [`nanoq`](https://github.com/esteinig/nanoq)

  - For pacbio:
    * [`lima`](https://lima.how/) to remove primers.

Assembly
  * k-mer based assessment of ONT reads via [`Jellyfish`](https://github.com/gmarcais/Jellyfish) and [`genomescope`](https://github.com/schatzlab/genomescope/)
  * Assemblies are performed with [`flye`](https://github.com/fenderglass/Flye),
  * or [`hifiasm`](https://github.com/chhylp123/hifiasm)

Polishing:
  * Polishing of ONT assemblies done using [`medaka`](https://github.com/nanoporetech/medaka)
  * Optional short-read polishing can be done using [`pilon`](https://github.com/broadinstitute/pilon) 

Scaffolding:
  * [`LINKS`](https://github.com/bcgsc/LINKS)
  * [`longstitch`](https://github.com/bcgsc/longstitch) 
  * [`ragtag`](https://github.com/malonge/RagTag)

Annotation:
  * Annotations are lifted from reference using [`liftoff`](https://github.com/agshumate/Liftoff).

QC: 
  * Quality of each stage is assessed using [`QUAST`](https://github.com/ablab/quast) and [`BUSCO`](https://gitlab.com/ezlab/busco) (standalone).
  * k-mer spectra can be used for further QC with [`yak`](https://github.com/lh3/yak)

# Tubemap

![Tubemap](assembly_v2.graph.png)

# Usage

Clone this repo:

```bash
git clone https://github.com/nschan/nf-arassembly/
```

Run via nextflow:

The standard pipeline assumes nanopore reads (10.14).

The samplesheet is a `.csv` file with a header. It _must_ adhere to this format, including the header row. Please note the absence of spaces after the commas:

```
sample,ontreads,ref_fasta,ref_gff
sampleName,path/to/reads,path/to/reference.fasta,path/to/reference.gff
```

To run the default pipeline with a samplesheet on biohpc_gen using charliecloud:

```bash
nextflow run nf-arassembly --samplesheet 'path/to/sample_sheet.csv' \
                           -profile charliecloud,biohpc_gen
```

# Parameters

See also [schema.md](schema.md)

| Parameter | Effect |
| --- | --- |
| **General parameters** | |
| `--samplesheet` | Path to samplesheet |
| `--use_ref` | Use a refence genome? (default: `true`) |
| `--lift_annotations` | Lift annotations from reference using [`liftoff`](https://github.com/agshumate/Liftoff)? Default: `true` |
| `--out` | Results directory, default: `'./results'` |
|`--ont` | ONT reads are available? These should go into the `ontreads` column of the samplesheet. Default: `false` |
| `--hifi` | Pacbio hifi reads are available? These should go into the `hifireads` column of the samplesheet. default: `false` |
| **ONT Preprocessing** | |
| `--collect` | Are the provided reads a folder (`true`) or a single fq files (default: `false` ) |
| `--porechop` | Run [`porechop`](https://github.com/rrwick/Porechop) on ONT reads? (default: `false`) |
| **pacbio Preprocessing** | |
| `--lima` | Run [`lima`](https://lima.how/) on pacbio reads? default: `false`|
| `--pacbio_primers` | Primers to be used with [`lima`](https://lima.how/) (required if `--lima` is used)? default: `null`|
| **Assembly** |  |
| `--assembler` | Assembler to use. Valid choices are: `'hifiasm'`, `'flye'`, or `'flye_on_hifiasm'`. `flye_on_hifiasm` will scaffold flye assembly (ont) on hifiasm (hifi) assembly using [`ragtag`](https://github.com/malonge/RagTag). Defaul: `'flye'`|
| **Assembly** | _`flye` specific arguments_ |
| `--flye_args` | The mode to be used by [`flye`](https://github.com/fenderglass/Flye); default: `"--nano-hq"`, options are: `"--pacbio-raw"`, `"--pacbio-corr"`, `"--pacbio-hifi"`, `"--nano-raw"`, `"--nano-corr"`, `"--nano-hq"` |
| `--kmer_length` | kmer size for [`Jellyfish`](https://github.com/gmarcais/Jellyfish)? (default: 21) |
| `--read_length` | Read length for [`genomescope`](https://github.com/schatzlab/genomescope/)? If this is `null` (default), the median read length estimated by [`nanoq`](https://github.com/esteinig/nanoq). will be used. If this is not `null`, the given value will be used for _all_ samples. |
| `--genome_size` | Expected genome size for [`flye`](https://github.com/fenderglass/Flye). If this is `null` (default), the haploid genome size for each sample will be estimated via [`genomescope`](https://github.com/schatzlab/genomescope/). If this is not `null`, the given value will be used for _all_ samples. |
| `--flye_args` | Arguments to be passed to [`flye`](https://github.com/fenderglass/Flye), default: `none`. Example: `--flye_args '--genome-size 130g --asm-coverage 50'` |
| **Assembly** | _`hifiasm` specific arguments_ |
| `--hifi_ont` | Use hifi and ONT reads with `hifiasm --ul`? default: `false`|
| `--hifiasm_args` | Extra arguments passed to [`hifiasm`](https://github.com/chhylp123/hifiasm). default: `''`|
| **Polishing** | |
| `--polish_medaka` | Polish using [`medaka`](https://github.com/nanoporetech/medaka), default: `false` |
| `--medaka_model` | Model used by [`medaka`](https://github.com/nanoporetech/medaka), default: 'r1041_e82_400bps_hac@v4.2.0:consesus' |
| `--polish_pilon` | Polish with short reads (see below) using [`pilon`](https://github.com/broadinstitute/pilon)? Sefault: `false` |
| **Scaffolding** | |
| `--scaffold_ragtag` | Scaffolding with [`ragtag`](https://github.com/malonge/RagTag)? Default: `false` |
| `--scaffold_links` | Scaffolding with [`LINKS`](https://github.com/bcgsc/LINKS)? Default: `false` |
| `--scaffold_longstitch` | Scaffolding with [`longstitch`](https://github.com/bcgsc/longstitch)? Default: `false` |
| **QC** | |
| `--short_reads` | Short reads available? These should go into `shortread_F` and `shortread_R` columns and the `paired` column should be true if both are filled. If only single-end reads are available, `shortread_R` remains empty, and `paired` is false. If short-reads are supplied, k-mer spectra will be used to assess quality of the assembly(s). Default: `false` |
| `--trim_short_reads` | Trim short reads with [`trimgalore`](https://github.com/FelixKrueger/TrimGalore)? Default: `true` |
| `--busco` | Run [`BUSCO`](https://gitlab.com/ezlab/busco)? Default: `'true'` |
| `--busco_db` | Path to local [`BUSCO`](https://gitlab.com/ezlab/busco) db? Default: `""` |
| `--busco_lineage` | [`BUSCO`](https://gitlab.com/ezlab/busco) lineage to use. Default: `brassicales_odb10` |
| `--quast`| Run [`QUAST`](https://github.com/ablab/quast)? Default: `true` |
| **Skipping steps** | |
| `--skip_assembly` | Skip assembly? Requires different samplesheet (!). Default: `false` |
| `--skip_alignments` | Skip alignments with [`minimap2`](https://github.com/lh3/minimap2)? Requires different samplesheet (!). Default: `false` |

# Included profiles

This pipelines comes with some profiles, which can be used via `-profile`. Since there are different ways to handle HiFi reads, and combinations of HiFI and ONT reads, I provide profiles for three common scenarios: 
  - Assembly of ONT via `flye`, assembly of HiFi via `hifiasm` and scaffolding of ONT assembly onto HiFi assembly: `ont_on_hifi`
  - Combined assembly of ONT and HiFi with `hifiasm`: `hifiasm_ul`
  - Assembly of only HiFi reads via `hifiasm`: `hifiasm`

| Name | Contents |
| --- | --- |
| `charliecloud` | Container configurations for charliecloud |
| `docker` | Container configurations for docker |
| `singularity` | Container configurations for singularity |
| `biohpc_gen` | Configuration to run on biohpc_gen SLURM cluster |
| `ont_on_hifi` | parameters for assembly of HiFi (via `hifiasm`) and ONT (via `flye`) and subsequent scaffolding of the ONT assembly onto HiFi assembly with `ragtag` |
| `hifi_ul` | parameters for the assembly of ONT and HiFI reads via `hifiasm` |
| `hifi_only` | parameters for assembly using only HiFi reads via `hifiasm` |

# Usage with PacBio reads

When pac-bio reads are used exclusively, and `flye` should be used for assembly, i suggest changing flye mode and skipping medaka.

```
--flye_mode '--pacbio-raw' --polish_medaka false
```

or, if HiFi reads are used:

```
--flye_mode '--pacbio-hifi' --polish_medaka false
```

## hifiasm

Alternatively, `hifiasm` can be used for assembly instead of flye using `--hifi`. Arguments to `hifiasm` can be passed via `--hifi_args`

The pipeline takes ONT and HiFi reads in the samplesheet like this:

```
sample,ontreads,hifireads,ref_fasta,ref_gff
sampleName,path/to/ontreads,path/to/hifireads.fq.gz,path/to/reference.fasta,path/to/reference.gff
```

There are two options when using `--hifi`, together with ONT reads, which are controlled by `--hifi_ont`:
 - If `--hifi_ont` is `false`, HiFi reads will be assembled via `hifiasm`, and used as a **scaffold** for the ONT reads assembled with `flye`, if `--scaffold_ragtag` is enabled. This will overide the standard procedure used in this pipeline, where the scaffolding would be done against the provided reference genome.
 - If `--hifi_ont` is `true`,  `hifiasm` will be used with `--ul` and the ONT reads will be used along the HiFi reads to assemble. If scaffolding against a reference is performed, the reference genome is used.

Another option is to use solely HiFi reads for assembly via `--hifi --hifi_only`.

To ease configuration there are three HiFi profiles included:

| Profile Name | Effect | Params |
|     ---      |  ---   |   ---  |
| `ont_on_hifi`  |  Use HiFi assembly as a scaffold for ONT reads | `--hifi --hifi_ont false --scaffold_ragtag` | 
| `hifiasm_ul`   |  Combine ONT and HiFI reads during `hifiasm` assembly | `--hifi --hifi_ont --polish_medaka false` |
| `hifi_only`    |  Use only HiFi reads for assembly via `hifiasm` | `--hifi --hifi_only --polish_medaka false` |

# Short reads: QC with yak

If short reads are available, [`yak`](https://github.com/lh3/yak) can be used to perform additional quality control based on kmer spectra.
This can be enabled using `--short_reads` and a samplesheet that looks like this:

```
sample,ontreads,ref_fasta,ref_gff,shortread_F,shortread_R,paired
sampleName,reads,assembly.fasta.gz,reference.fasta,reference.gff,short_F1.fastq,short_F2.fastq,true
```

If there are only single-end reads, shortread_R should remain empty, and paired should be `false`

# Short reads: Polishing with pilon

The assemblies can be polished using available short-reads using [`pilon`](https://github.com/broadinstitute/pilon).
`--polish_pilon`

This requires additional information in the samplesheet: `shortread_F`, `shortread_R` and `paired`:

```
sample,ontreads,ref_fasta,ref_gff,shortread_F,shortread_R,paired
sampleName,reads,assembly.fasta.gz,reference.fasta,reference.gff,short_F1.fastq,short_F2.fastq,true
```

In a case where only single-reads are available, `shortread_R` should be empty, and `paired` should be false.

# Scaffolding

[`LINKS`](https://github.com/bcgsc/LINKS), [`longstitch`](https://github.com/bcgsc/longstitch) and / or [`ragtag`](https://github.com/malonge/RagTag) can be used for scaffolding.

# Using liftoff

If `--lift_annotations` is used (default), the annotations from the reference genome will be mapped to assemblies and scaffolds using liftoff.
This will happen at each step of the pipeline where a new genome fasta is created, i.e. after assembly, after polishing and after scaffolding.

# No refence genome

If there is no reference genome available use `--use_ref false` to disable the reference genome.
Liftoff should not be used without a reference, QUAST will no longer compare to reference. 

# Skipping Flye

In case you already have an assembly and would only like to check it with QUAST and polish use
`--skip_flye true`

This mode requires a different samplesheet:

```
sample,readpath,assembly,ref_fasta,ref_gff
sampleName,path/to/reads,assembly.fasta.gz,reference.fasta,reference.gff
```

When skipping flye the original reads will be mapped to the assembly and the reference genome.

# Skipping Flye and mappings

In case you have an assembly and have already mapped your reads to the assembly and the reference genome you can use
`--skip_flye true --skip_alignments true`

This mode requires a different samplesheet:

```
sample,readpath,assembly,ref_fasta,ref_gff,assembly_bam,assembly_bai,ref_bam
sampleName,reads,assembly.fasta.gz,reference.fasta,reference.gff,reads_on_assembly.bam,reads_on_assembly.bai,reads_on_reference.bam
```

# QUAST

[`QUAST`](https://github.com/ablab/quast) will run with the following additional parameters:

```
        --eukaryote \\
        --glimmer \\
        --conserved-genes-finding \\
```

# Acknowledgements

This pipeline builds on [modules](https://github.com/nf-core/modules) developed by [`nf-core`](https://nf-co.re). 