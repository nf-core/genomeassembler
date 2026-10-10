# FAIR bioHeaders YAML export

Pass `--fhr_config fhr_config.json` to create FHR YAML for each retained assembly
stage, including both haplotypes when Hi-C phasing is enabled. Without that
parameter, no FHR tasks run.

The integration uses the reusable [FHR-Nextflow](https://github.com/FAIR-bioHeaders/FHR-Nextflow)
modules, vendored at commit `6fac9f57bf11d4e63461f2dca5f69d4856fa3cc8` with their
MPL-2.0 notices. FHR-File-Converter **0.3.0** performs schema validation,
conversion and checksums. FHR-Nextflow is a development prototype; the integration
has been tested with Nextflow **26.04.6**, Java **21** and that converter version.

## Input config

Copy `assets/fhr_config.example.json` to `fhr_config.json` and replace the marked
values. The input is JSON; the generated FHR sidecar is YAML. Keeping the config
in JSON lets Nextflow load metadata natively without another parsing dependency.

```json
{
  "defaults": {
    "schema": "https://raw.githubusercontent.com/FAIR-bioHeaders/FHR-Specification/v0.3.0/fhr.json",
    "schemaVersion": 1,
    "version": "1.0",
    "metadataAuthor": [{ "name": "Your metadata author" }],
    "assemblyAuthor": [{ "name": "Your assembly author" }],
    "masking": "not-masked"
  },
  "samples": {
    "individual": {
      "genome": "Your assembly name",
      "taxon": {
        "name": "Your organism name",
        "uri": "https://identifiers.org/taxonomy:YOUR_TAXON_ID"
      }
    }
  }
}
```

These are example values, not inferred provenance. Use the actual masking state. `dateCreated` is generated from the current date
in America/Detroit when the record is created, replacing any supplied date. Every sample must have an entry in `samples`;
keys match samplesheet IDs. Metadata is `defaults` plus the sample object, with
sample values taking priority. The merge replaces whole top-level fields, so an
overridden `taxon` object or author list must be complete. All FHR fields are
accepted; the converter rejects unknown or invalid fields using its bundled
schema. `defaults` and `samples` are the only envelope keys.

Required metadata includes `schema`, `schemaVersion`, `genome`, `taxon`,
`version`, `metadataAuthor`, `assemblyAuthor` and `masking`.
`dateCreated` and `checksum` are calculated automatically.
Do not supply `checksum`: attachment calculates the real value. If supplied,
it is replaced. Optional accession, author URIs, software provenance, funding,
SeqCol IDs and other FHR fields may be added when known. Software versions and
SeqCol identity are not guessed. Omit assembly-specific `vitalStats` and
`seqcol_id` when a shared config covers stages whose sequences differ; supplied
values are preserved and are not verified against the assembly.

For phased assemblies, `individual-hap1` and `individual-hap2` inherit the
`individual` entry. Add explicit derived sample entries to override each
haplotype's metadata. A derived entry replaces the source entry and is merged
with shared defaults.

## Runtime

For Docker, build the bundled upstream image first:

```bash
docker build -t fhr-nextflow:0.1.0 modules/local/fhr
nextflow run . -profile docker --input samplesheet.csv --outdir results \
    --fhr_config fhr_config.json
```

The tag is a **local build tag**, not a published image. Use `--fhr_container`
to specify your own registry image or an Apptainer/Singularity-compatible image
accessible to the executor. The image must contain FHR-File-Converter 0.3.0.
A pinned conda environment is also included for `-profile conda`. When running
without containers or conda, install the converter's pinned environment and
make its commands available on every worker. No remote service is contacted
for metadata validation once the converter is installed.

## Outputs and checksum meaning

For each sample and retained stage:

```text
results/individual/fhr/initial_assembly/
    individual-initial_assembly.fhr.yaml
    individual-initial_assembly.fhr.fasta
```

Other stages use `polish_pilon`, `polish_medaka`, `polish_dorado`,
`scaffold_hic`, `scaffold_ragtag`, `scaffold_longstitch` and `scaffold_links`
when the pipeline retains those outputs. Phased assemblies use the derived
sample directory. Stage IDs follow the existing genomeqc manifest's naming.

Compressed FASTA is decompressed without reformatting sequence bytes. FHR-Nextflow
attaches metadata, calculates the SHA-512/256 checksum, validates that annotated
FASTA, extracts matching metadata, converts it to YAML and validates the YAML.
Only validated YAML and annotated FASTA are published. The original pipeline
assembly is retained unchanged. Intermediates and validation logs stay in the
Nextflow work directory; converter versions join the pipeline version report.

The YAML checksum refers to the **paired annotated FASTA**, excluding its root
checksum header line. It is not a checksum of the original compressed assembly
or of sequence letters alone. Existing FHR header lines are replaced by the
converter; all other sequence-file bytes are preserved. An invalid config or
metadata record fails the run. Outputs from other successful records may already
have been published; run failure does not roll back published files.

## Verification

Install `tests/fhr/requirements.txt` in an isolated Python environment, then run
with Nextflow available:

```bash
python tests/fhr/run.py --nextflow nextflow
# After building the bundled image:
python tests/fhr/run.py --nextflow nextflow --profile docker
```

The integration harness runs the actual upstream modules on synthetic FASTA
files. It checks multiple samples/stages, compressed and plain input, CRLF byte
preservation, metadata quoting, source-sample inheritance, haplotype overrides,
matching YAML/FASTA checksums, and rejection of missing metadata, unknown fields
and unsafe IDs. It also checks the automatic creation date and that a disabled
export schedules no tasks. The dedicated CI workflow runs native and Docker
variants. It does not run the full genome assembly pipeline or benchmark
large-genome memory requirements. The converter loads complete files in memory;
increase the `fhr` process memory through a custom Nextflow config for large
assemblies. Container and conda execution need their own environment verification.
