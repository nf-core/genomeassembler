# OTB integration

This fork builds on nf-core/genomeassembler. OTB's most distinctive feature is its
focus on phased HiFi assemblies with Hi-C support. Genomeassembler already provides
GenomeScope, BUSCO, Merqury, RagTag and YaHS, so those components do not need duplicating.

## Diploid HiFi + Hi-C phasing

Enable `hifiasm_hic_phasing` in a samplesheet row or pass
`--hifiasm_hic_phasing` to enable it globally. The default is false.

```csv
sample,strategy,assembler,hifireads,hic_F,hic_R,hifiasm_hic_phasing,hic_trim
individual,single,hifiasm,/data/hifi.fastq.gz,/data/hic_R1.fastq.gz,/data/hic_R2.fastq.gz,true,false
```

```bash
nextflow run . -profile docker --input samplesheet.csv --outdir results
```

This mode requires HiFi reads, both Hi-C mates, the single assembly strategy and
hifiasm. It rejects ONT inputs and pre-existing assemblies. Hi-C reads are supplied
as provided; `hic_trim` must be false. HiFi preparation remains the pipeline's
existing fastplong preparation. Choose diploid-compatible hifiasm arguments and
avoid output-changing arguments such as `--primary`.

The workflow stages each sample's HiFi reads and Hi-C pair together, invokes
hifiasm's `--h1` and `--h2` mode, and converts both phased GFA outputs to FASTA.
The original hifiasm graphs and logs are published under the source sample.
Haplotypes become separate downstream samples named `individual-hap1` and
`individual-hap2`, retaining `source_sample` and `haplotype` metadata. Reserve
these derived sample names: the pipeline rejects collisions with other input sample names.

Compressed assemblies are published at:

- `results/individual-hap1/assembly/hifiasm/individual-hap1.fa.gz`
- `results/individual-hap2/assembly/hifiasm/individual-hap2.fa.gz`

Each haplotype follows the existing QC, polishing and scaffolding settings,
and receives its own genomeqc manifest rows. `scaffold_hic` independently enables
YaHS scaffolding for both haplotypes using the same original Hi-C pair. Merqury
uses the source sample's read k-mer database for each haplotype; this does not
measure switch errors or parental phase accuracy. The aggregate report lists the derived haplotype samples.

## Other OTB ideas

| OTB idea | Decision |
| --- | --- |
| Stage-wise assembly assessment | Keep existing BUSCO, QUAST and Merqury integration. |
| GenomeScope profiling | Keep existing Jellyfish/GenomeScope integration. |
| YaHS scaffolding and RagTag reference scaffolding | Reuse existing subworkflows for each haplotype. |
| Trio phasing with parental yak databases | Valuable next addition; needs parental input validation and dedicated tests. |
| FCS-adaptor screening | Valuable future addition; requires a versioned supported module and clear cleaned-assembly provenance. |
| HiFiAdapterFilt | Evaluate against existing HiFi fastplong preparation before adding another filtering option. |
| Merfin / DeepVariant HiFi polishing | Defer until supported models and evidence demonstrate improvement without collapsing haplotypes. |
| Shhquis contact-driven reorientation | Defer pending comparison with the existing YaHS path. |

The phased assembly routing has an nf-test stub regression and a standalone
container-backed routing harness covering two samples
and four distinct haplotypes. Run it in a configured Nextflow/nf-test environment:

```bash
nf-test test subworkflows/local/assemble/tests/hic_phasing.nf.test --profile docker
```

Stub tests check routing and naming. A real HiFi + Hi-C dataset run is still
needed to validate assembly quality and downstream biological results.
