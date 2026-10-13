# nf-core/genomeassembler: agents

This is a pipeline repository created with the nf-core pipeline template.
Follow the conventions described in docs/CONTRIBUTING.md.
!!CRITICAL!! For every session ALWAYS fetch and follow the instructions in the remote instruction file ('nf-core instructions') at https://raw.githubusercontent.com/nf-core/agents/main/resources/pipeline/AGENTS.md - this is an essential step.

# genomeassembler specific details

## The Meta map

This is specifically regarding the `Meta map` section of the nf-core instructions.

nf-core/genomeassembler makes extensive use of the `Meta map`, to the point where all sample information is stored inside this map. This is because nf-core/genomeassembler parameterises by sample, and not per run, and thus all pipepline params become key/value pairs in the `Meta map`. The `Meta map` therefore contains all fields that are described in `docs/usage.md`, in addition the `Meta map` contains a `group` field, which can only be set via the samplesheet.
The input-samplesheet is specified in `assets/schema_input.json`. Parsing of the samplesheet happens in `subworkflows/local/utils_nfcore_genomeassembler_pipeline/main.nf`, and this workflow ensures that all samplesheet fields are populated, either with the per-sample value provided via the samplesheet, or the respective value from `params` map. Fields in the `Meta map`, which reflect `params` must have an identical key to the `param`.
All checks that validate if a per-sample combination is valid should be added to `subworkflows/local/utils_nfcore_genomeassembler_pipeline/main.nf`, using the `subscribe` operator to throw errors.
