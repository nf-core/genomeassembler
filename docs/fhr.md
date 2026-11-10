# FAIR bioHeaders YAML export

Pass `--fhr_config fhr_config.json` to create FHR YAML for each retained assembly
stage. This branch does not add phased assembly generation; export of both
haplotypes depends on the separate phasing integration supplying those records. Without that
parameter, no FHR tasks run.

Export uses the nf-core `fairbioheaders/combine`, `verify`, `convert` and
`validate` modules with fair-bioheaders **0.9.0** and the FHR **2.0** contract.
The verify and convert modules are pinned to the heads of nf-core/modules
#13635 and #13636 while those PRs are open.
Update legacy schema-1 configuration to the schema URL and version below.

## Input config

Copy `assets/fhr_config.example.json` to `fhr_config.json` and replace the marked
values. The input is JSON; the generated FHR sidecar is YAML. Keeping the config
in JSON lets Nextflow load metadata natively without another parsing dependency.

```json
{
  "defaults": {
    "schema": "https://w3id.org/fair-bioheaders/fhr/v0.4.0",
    "schemaVersion": "2.0",
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

The export helpers support derived records supplied by a future phasing integration:
`individual-hap1` and `individual-hap2` inherit the
`individual` entry. Add explicit derived sample entries to override each
haplotype's metadata. A derived entry replaces the source entry and is merged
with shared defaults.

## Runtime

The nf-core modules select their published containers or pinned Conda environment
through the pipeline profile.

```bash
nextflow run . -profile docker --input samplesheet.csv --outdir results \
    --fhr_config fhr_config.json
```

For native execution, install fair-bioheaders 0.9.0 on every worker.
Set `--fhr_container` to use a custom image containing that version.

## Outputs and checksum meaning

For each sample and retained stage:

```text
results/individual/fhr/initial_assembly/
    individual-initial_assembly.fhr.yaml
    individual-initial_assembly.fhr.fasta
```

Other stages use `polish_pilon`, `polish_medaka`, `polish_dorado`,
`scaffold_hic`, `scaffold_ragtag`, `scaffold_longstitch` and `scaffold_links`
when the pipeline retains those outputs. If a phasing integration supplies derived records, they use the derived
sample directory. Stage IDs follow the existing genomeqc manifest's naming.

Repeated export records sharing a sample and stage identity are deduplicated. RagTag can produce different results from different upstream scaffold paths, so its export stage is `scaffold_ragtag-<SHA-256 of the assembly path>`. Every distinct RagTag path is exported; repeats of the same path share an export identity. Path digests depend on the input path, not sequence contents.
Ordinary alphanumeric sample IDs retain their names. IDs containing punctuation
outside letters, digits, dot, underscore and hyphen (or starting with a non-alphanumeric
character), and IDs longer than 100 characters, are encoded as `fhr-encoded-` followed by the SHA-256 digest of their UTF-8 bytes. This keeps filenames bounded even after stage names and extensions are appended.
The prefix is reserved: literal IDs starting with it are also encoded, preventing
collisions. Metadata config keys always use the original samplesheet ID; output
directories and filenames use the encoded ID when needed.

Compressed FASTA is decompressed without reformatting sequence bytes. The
combine module attaches metadata and calculates the SHA-512/256 checksum. The
verify module checks the header and checksum before conversion to YAML. The
validate module checks the YAML before the pair is published.
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
python tests/fhr/run.py --nextflow nextflow --profile docker
```

The integration harness runs the actual upstream modules on synthetic FASTA
files. It checks multiple samples/stages, compressed and plain input, CRLF byte
preservation, metadata quoting, source-sample inheritance, haplotype overrides,
matching YAML/FASTA checksums, rejection of missing metadata and unknown fields,
safe encoding of punctuation/traversal-like IDs, duplicate-stage records and
preservation of earlier polishing stages. It also checks the automatic creation date and that a disabled
export schedules no tasks. The dedicated CI workflow runs native and Docker
variants. It does not run the full genome assembly pipeline. Export tasks request
a 6 GB minimum and, after decompression, at least 12 times the FASTA byte size.
Memory scales with the retry attempt. This is a conservative allocation that
can be overridden in the process configuration.

## Native converter memory benchmark

`tests/fhr/benchmark.py` measures the four current fair-bioheaders commands on
synthetic FASTA files, outside Nextflow and containers.

```bash
python tests/fhr/benchmark.py --sizes-mib 16 64 256 --repeats 3 \
    --output fhr-memory-benchmark.json
```

The [October 11 baseline](fhr-memory-benchmark.json) was measured with
FHR-File-Converter 0.3.0 and describes the previous implementation.
