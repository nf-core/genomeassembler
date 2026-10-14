include { createHaplotypePrefix } from '../subworkflows/local/assembly_haplotypes/main'
// Multiple scaffold outputs can belong to the same sample or haplotype.
workflow REPORT_SAMPLES {
    take:
    assemblies

    main:
    groups = assemblies
        .map { row -> [sample: [id: createHaplotypePrefix(row.meta), sample_id: row.meta.id, haplotype: row.meta.haplotype ?: null, group: row.meta.group]] }
        .unique { row -> [row.sample.sample_id, row.sample.haplotype] }
        .collect()

    emit:
    groups
}
