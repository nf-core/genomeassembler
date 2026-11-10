include { sampleId } from '../../../modules/local/fhr/upstream/modules/utils/main'
include { FHR_FINALIZE } from '../../../modules/local/fhr/finalize/main'
include { FHR_PREPARE_SEQUENCE } from '../../../modules/local/fhr/prepare_sequence/main'
include { FHR_WRITE_JSON } from '../../../modules/local/fhr/upstream/modules/create_json/main'
include { FAIRBIOHEADERS_COMBINE } from '../../../modules/nf-core/fairbioheaders/combine/main'
include { FAIRBIOHEADERS_VERIFY } from '../../../modules/nf-core/fairbioheaders/verify/main'
include { FAIRBIOHEADERS_CONVERT } from '../../../modules/nf-core/fairbioheaders/convert/main'
include { FAIRBIOHEADERS_VALIDATE } from '../../../modules/nf-core/fairbioheaders/validate/main'

workflow FHR_EXPORT {
    take:
    records // tuple(meta, FHR fields map, assembly path)

    main:
    // Parallel scaffolding paths can repeat the same sample/stage record.
    unique_records = records.unique { meta, fields, assembly -> meta.id }
    FHR_PREPARE_SEQUENCE(unique_records)
    sequences = FHR_PREPARE_SEQUENCE.out.sequence.map { meta, fields, fasta ->
        tuple(meta + [fhr_sequence_bytes: fasta.size()], fields, fasta)
    }
    // Attachment computes the checksum before validating metadata. No placeholder
    // checksum is required in the user's config or exposed as a validated output.
    FHR_WRITE_JSON(sequences.map { meta, fields, fasta -> tuple(meta, fields) })
    paired = FHR_WRITE_JSON.out.json
        .map { meta, json -> tuple(meta.id, meta, json) }
        .join(sequences.map { meta, fields, fasta -> tuple(meta.id, fasta) }, failOnDuplicate: true, failOnMismatch: true)
        .map { id, meta, json, fasta -> tuple(meta, json, fasta) }
    FAIRBIOHEADERS_COMBINE(paired)
    FAIRBIOHEADERS_VERIFY(FAIRBIOHEADERS_COMBINE.out.sequence)

    // A report is emitted only when verification succeeds.
    verified = FAIRBIOHEADERS_COMBINE.out.sequence
        .map { meta, fasta -> tuple(meta.id, meta, fasta) }
        .join(FAIRBIOHEADERS_VERIFY.out.report.map { meta, report -> tuple(meta.id) }, failOnDuplicate: true, failOnMismatch: true)
        .map { id, meta, fasta -> tuple(meta, fasta) }
    FAIRBIOHEADERS_CONVERT(verified, 'yaml')
    FAIRBIOHEADERS_VALIDATE(FAIRBIOHEADERS_CONVERT.out.metadata)

    checked_yaml = FAIRBIOHEADERS_CONVERT.out.metadata
        .map { meta, yaml -> tuple(meta.id, yaml) }
        .join(FAIRBIOHEADERS_VALIDATE.out.report.map { meta, report -> tuple(meta.id) }, failOnDuplicate: true, failOnMismatch: true)
    validated_pairs = verified
        .map { meta, fasta -> tuple(meta.id, meta, fasta) }
        .join(checked_yaml, failOnDuplicate: true, failOnMismatch: true)
        .map { id, meta, fasta, yaml -> tuple(meta, fasta, yaml) }
    FHR_FINALIZE(validated_pairs)

    emit:
    sequence = FHR_FINALIZE.out.sequence
    yaml = FHR_FINALIZE.out.yaml
    reports = FAIRBIOHEADERS_VERIFY.out.report.mix(FAIRBIOHEADERS_VALIDATE.out.report)
}

// Parse only the input envelope; schema validation belongs to fair-bioheaders.
def loadFhrConfig(path) {
    def config = new groovy.json.JsonSlurper().parseText(file(path, checkIfExists: true).text)
    if (!(config instanceof Map) || !(config.defaults instanceof Map) || !(config.samples instanceof Map)) {
        throw new IllegalArgumentException('FHR config must be a JSON object with defaults and samples objects')
    }
    if (config.keySet().any { !(it in ['defaults', 'samples']) } || config.samples.values().any { !(it instanceof Map) }) {
        throw new IllegalArgumentException('FHR config supports only defaults and samples; each sample must be a metadata object')
    }
    return config
}

def fhrRecord(meta, stage, assembly, config) {
    // RagTag can run once per upstream scaffold path. Keep each result while
    // giving repeat records for the same path the same export identity.
    if (stage == 'scaffold_ragtag') {
        def path_digest = java.security.MessageDigest.getInstance('SHA-256')
            .digest(assembly.toString().getBytes('UTF-8')).encodeHex().toString()
        stage = "${stage}-${path_digest}".toString()
    }
    def sample = meta.id.toString()
    def source = (meta.source_sample ?: sample).toString()
    def key = config.samples.containsKey(sample) ? sample : source
    if (!config.samples.containsKey(key)) {
        throw new IllegalArgumentException("FHR config is missing metadata for sample '${sample}' (source '${source}')")
    }
    def fields = config.defaults + config.samples[key] + [
        dateCreated: java.time.LocalDate.now(java.time.ZoneId.of('America/Detroit')).toString()
    ]
    def safe_sample = fhrSampleId(sample)
    def id = "${safe_sample}-${stage}".toString()
    sampleId([id: id])
    return tuple([id: id, sample: safe_sample, original_sample: sample, source_sample: source, stage: stage], fields, assembly)
}

// Reserve the encoding prefix so an encoded ID cannot collide with a literal ID.
// Metadata lookup continues to use the original samplesheet ID.
def fhrSampleId(sample) {
    def value = sample.toString()
    return value.length() <= 100 && value ==~ /[A-Za-z0-9][A-Za-z0-9_.-]*/ && !value.startsWith('fhr-encoded-')
        ? value : 'fhr-encoded-' + java.security.MessageDigest.getInstance('SHA-256').digest(value.getBytes('UTF-8')).encodeHex().toString()
}

// Assembly stages have parallel outputs; no arbitrary "final" precedence is applied.
def assemblyOutputs(meta) {
    def subout = meta.strategy == 'single'
        ? (meta.assembler_ont == 'flye' || meta.assembler_hifi == 'flye'
            ? 'assembly/flye' : meta.assembler_ont == 'hifiasm'
                ? 'assembly/hifiasm_ont' : 'assembly/hifiasm')
        : meta.strategy == 'hybrid' ? 'assembly/hifiasm' : 'assembly/ragtag'
    return [
        [meta, 'scaffold_ragtag', meta.scaffolds?.ragtag, 'scaffold/ragtag'],
        [meta, 'scaffold_hic', meta.scaffolds?.hic, 'scaffold/hic/yahs'],
        [meta, 'scaffold_longstitch', meta.scaffolds?.longstitch, 'scaffold/longstitch'],
        [meta, 'scaffold_links', meta.scaffolds?.links, 'scaffold/links'],
        [meta, 'polish_pilon', meta.polished?.pilon, 'polish/pilon'],
        [meta, 'polish_medaka', meta.polished?.medaka, 'polish/medaka'],
        [meta, 'polish_dorado', meta.polished?.dorado ?: meta.polished?.polished_dorado, 'polish/dorado'],
        [meta, 'initial_assembly', meta.assembly, subout]
    ].findAll { it[2] != null }
}
