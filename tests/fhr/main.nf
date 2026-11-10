include { FHR_EXPORT ; assemblyOutputs ; fhrRecord } from '../../subworkflows/local/fhr/main'

workflow TEST_FHR_EXPORT {
    take:
    mode

    main:
    def fixtures = java.nio.file.Files.createTempDirectory(file(params.outdir).parent, 'fhr-fixtures-')
    def plain = fixtures.resolve('assembly.fa')
    plain.text = '>contig1\r\nACGTACGT\r\n'
    def compressed = fixtures.resolve('assembly.fa.gz')
    compressed.withOutputStream { raw ->
        new java.util.zip.GZIPOutputStream(raw).withCloseable { gzip -> gzip.write(plain.bytes) }
    }
    def alternate = fixtures.resolve('scaffold.fa')
    alternate.text = '>scaffold1\nTTTTACGT\n'

    def config = [defaults: [schema: 'https://w3id.org/fair-bioheaders/fhr/v0.4.0', schemaVersion: '2.0', version: '1.0', metadataAuthor: [[name: 'Synthetic author']], assemblyAuthor: [[name: 'Synthetic assembler']], masking: 'not-masked'], samples: [alpha: [genome: 'Synthetic assembly', taxon: [name: 'Synthetic taxon', uri: 'https://identifiers.org/taxonomy:9606']]]]
    if (mode == 'invalid') {
        config.defaults.remove('assemblyAuthor')
    }

    def meta = [id: 'alpha-hap1', source_sample: 'alpha', strategy: 'single', assembler_hifi: 'hifiasm', assembly: plain, polished: [polished_dorado: compressed], scaffolds: [ragtag: compressed]]
    def alternate_meta = meta + [scaffolds: [ragtag: alternate]]
    records = mode == 'disabled'
        ? channel.empty()
        : channel.of(meta, alternate_meta, meta).flatMap { row -> assemblyOutputs(row) }.map { row, stage, assembly, subdir -> fhrRecord(row, stage, assembly, config) }
    FHR_EXPORT(records)

    emit:
    sequence = FHR_EXPORT.out.sequence
    yaml = FHR_EXPORT.out.yaml
}
