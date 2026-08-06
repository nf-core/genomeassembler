# nf-core/genomeassembler: Changelog

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## v2.0.0 - 'Saffron Vulture' - [2026-xx-xx]

This is a major release, with breaking changes.

The pipeline now implements topics to collect software version, the minimum `nextflow` version is `25.10.0`.

v2.0.0 of genomeassembler is a large refactor of the pipeline to facilitate sample-level parameteristation. This allows to either parameterise the _pipeline_ using `params`, or parameterise _samples_ via the `input` samplesheet. In case both types of parameterisations are used, sample parameters will take priority.

Since this workflow follows a sample-centric implementation, nextflow will always render the full pipeline dag, but depending on configuration samples may not travel through the whole pipeline. This may also cause terminal output to show task instances that will never become an active process.

In addition, v2.0.0 contains these changes:

### `Added`

Pull requests in reverse chronological order since v1.1.0

[#171](https://github.com/nf-core/genomeassembler/issues/171)

- fastplong for long-read trimming and qc
- fastp for short-read trimming and qc
- migration to nf-test
- increased flexibility of the scaffolding strategy
- added option to group samples
- `dorado polish` added as an alternative to `medaka` for ONT polishing. This is an **experimental feature**, due to `dorado` being under active development.
- HiC scaffolding subworkflow:
  - mapping with `bwamem2` or `minimap2`
  - duplicate removal with `picard`
  - scaffolding with `yahs`
- Switched to the versions topic, requires nextflow >=25.10.0

[#185](https://github.com/nf-core/genomeassembler/issues/180)

- Template update to 4.0.2

[#180](https://github.com/nf-core/genomeassembler/issues/180)

- Template update to 3.5.1

[#177](https://github.com/nf-core/genomeassembler/issues/177)

- Template update to 3.4.1

[#164](https://github.com/nf-core/genomeassembler/issues/164)

- Template update to 3.3.1

### `Fixed`

[#176](https://github.com/nf-core/genomeassembler/issues/176)

- Fixed typo in medaka url (@TomHarrop)

### `Dependencies`

#### New

The following modules have been added:

| name      | v1.1.0 | v2.0.0          |
| --------- | ------ | --------------- |
| dorado    | -      | 1.3.1+7c84b01de |
| bwamem2   | -      | 2.3             |
| fastp     | -      | 1.0.1           |
| fastplong | -      | 0.3.0           |
| gfatools  | -      | 0.5             |
| htslib    | -      | 1.23.1          |
| picard    | -      | 3.4.0           |
| yahs      | -      | 1.2.2           |

#### Updated

The following tools have been updated to a new version:

| name         | v1.1.0 | v2.0.0 |
| ------------ | ------ | ------ |
| genomescope2 | 2.0    | 2.0.0  |
| busco        | 5.8.3  | 6.0.0  |

#### `Deprecated`

The following tools have been deprecated:

| name       | v1.1.0 | v2.0.0                   |
| ---------- | ------ | ------------------------ |
| nanoq      | 0.10.0 | deprecated               |
| lima       | 2.12.0 | deprecated               |
| porechop   | 0.2.4  | deprecated               |
| pigz       | 2.8    | deprecated with porechop |
| trimgalore | 0.6.10 | deprecated               |
| cutadapt   | 4.9    | deprecated               |

The following param is no longer implemented:

- `dump`, used to dump jellyfish output.

#### Unchanged

The following tools are unchanged:

| name       | v1.1.0 | v2.0.0 |
| ---------- | ------ | ------ |
| coreutils  | 9.5    | 9.5    |
| jellyfish  | 2.3.1  | 2.3.1  |
| longstitch | 1.0.5  | 1.0.5  |
| medaka     | 1.11.3 | 1.11.3 |
| quast      | 5.3.0  | 5.3.0  |
| quarto     | 1.7.31 | 1.7.31 |
| fastqc     | 0.12.1 | 0.12.1 |
| flye       | 2.9.5  | 2.9.5  |
| hifiasm    | 0.25.0 | 0.25.0 |
| liftoff    | 1.6.3  | 1.6.3  |
| links      | 2.0.1  | 2.0.1  |
| merqury    | 1.3    | 1.3    |
| meryl      | 1.4.1  | 1.4.1  |
| minimap2   | 2.29   | 2.29   |
| samtools   | 1.21   | 1.21   |
| pilon      | 1.24   | 1.24   |
| ragtag     | 2.1.0  | 2.1.0  |

## v1.1.0 'Brass Pigeon' - [2025-07-21]

### `Added`

[#170](https://github.com/nf-core/genomeassembler/issues/170) - Switched to nf-core template 3.3.2

[#164](https://github.com/nf-core/genomeassembler/issues/164) - Switched to nf-core template 3.3.1

[#153](https://github.com/nf-core/genomeassembler/issues/153) - Switched to nf-core template 3.2.1

[#144](https://github.com/nf-core/genomeassembler/issues/144) - Added `hifiasm_on_hifiasm` assembly strategy

[#158](https://github.com/nf-core/genomeassembler/pull/158) - Added tables for QUAST and BUSCO to report, (using `gt`, added `gt` to container and env)

### `Fixed`

[#169](https://github.com/nf-core/genomeassembler/pull/169) - Module mainencance: gfa2fa container and conda env now report the same version of `mawk`.

[#154](https://github.com/nf-core/genomeassembler/pull/154) - Module maintenance:

- updated `hifiasm`, `minimap2`, `links` nf-core modules
- updated container in local `quast` module
- separated `modules.config` into several files for easier navigation and maintenance

[#138](https://github.com/nf-core/genomeassembler/pull/138) - Switched to RagTag nf-core module

[#142](https://github.com/nf-core/genomeassembler/pull/142) - Switch `--collect` to accept a glob pattern instead of a folder, consistent with input validation.

[#131](https://github.com/nf-core/genomeassembler/pull/131) - Refactored QC steps into subworkflow.

[#133](https://github.com/nf-core/genomeassembler/pull/133) - Updated the input validation to be more strict. This should prevent some down the line errors in the pipeline

[#136](https://github.com/nf-core/genomeassembler/pull/136) - Switched to using ragtag `patch` instead of `scaffold` for `flye_on_hifiasm`

[#145](https://github.com/nf-core/genomeassembler/pull/145) - Fixed `--skip_assembly` input validation bug.

[#148](https://github.com/nf-core/genomeassembler/pull/148) - Switched to LINKS nf-core module

### `Dependencies`

### `Deprecated`

## v1.0.1 'Aluminium Pigeon' - [2025-03-19]

Bugfix release

### `Added`

### `Fixed`

[#125](https://github.com/nf-core/genomeassembler/pull/125) - use correct genome-size for flye and longstitch.

[#126](https://github.com/nf-core/genomeassembler/pull/126) - fixed wrong url for jellyfish singularity image.

### `Dependencies`

### `Deprecated`

## v1.0.0 'Lead Pigeon' - [2025-03-07]

Initial release of nf-core/genomeassembler, created with the [nf-core](https://nf-co.re/) template.

### `Added`

### `Fixed`

### `Dependencies`

### `Deprecated`

Codenames for v1.x are various types of metallic pigeons, v2.x are vultures of different colors.
