# nf-core/genomeassembler: Changelog

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/)
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## v1.1.0 'Brass Pigeon' - [2025-03-19]

### `Added`

[#153](https://github.com/nf-core/genomeassembler/issues/153) - Switched to nf-core template 3.2.1

[#144](https://github.com/nf-core/genomeassembler/issues/144) - Added `hifiasm_on_hifiasm` assembly strategy

### `Fixed`

[#154](https://github.com/nf-core/genomeassembler/pull/154) - Module maintainance:

- updated `hifiasm`, `minimap2`, `links` nf-core modules
- updated container in local `quast` module
- separated `modules.config` into several files for easier navigation and maintainance

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
