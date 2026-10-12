// Sample identity stays stable; assembly joins distinguish the haplotype as well.
def assemblyKey(meta) {
    [meta.id, meta.haplotype ?: null]
}

def assemblyPrefix(meta) {
    meta.haplotype ? "${meta.id}_${meta.haplotype}".toString() : meta.id.toString()
}

// Create independent maps for per-assembly tasks without changing the sample ID.
def expandHaplotypes(row) {
    if (!row.meta.haplotypes) return [row]
    row.meta.haplotypes.collect { haplotype, assembly ->
        def stages = (row.meta.haplotype_results?.get(haplotype) ?: [:]).collectEntries { stage, files ->
            [(stage): files + [:]]
        }
        [meta: row.meta + stages + [haplotype: haplotype, assembly: assembly, assembly_map_bam: null]]
    }
}

workflow COLLATE_HAPLOTYPES {
    take:
    assemblies

    main:
    branched = assemblies.branch { row ->
        phased: row.meta.haplotype
        unphased: true
    }
    samples = branched.phased
        .map { row -> [row.meta.id, row.meta] }
        .groupTuple()
        .map { id, metas ->
            def by_haplotype = metas.groupBy { it.haplotype }
            if (by_haplotype.keySet() != ['hap1', 'hap2'].toSet()) {
                error("Sample ${id}: expected assemblies for both hap1 and hap2.")
            }
            def haplotypes = by_haplotype.collectEntries { haplotype, records ->
                def files = records*.assembly.unique()
                if (files.size() != 1) error("Sample ${id}: conflicting initial assemblies for ${haplotype}.")
                [(haplotype): files[0]]
            }
            def results = by_haplotype.collectEntries { haplotype, records ->
                def stages = ['polished', 'scaffolds'].collectEntries { stage ->
                    def entries = records.collectMany { (it[stage] ?: [:]).entrySet().toList() }.groupBy { it.key }
                    def merged = entries.collectEntries { key, values ->
                        def paths = values*.value.unique()
                        if (paths.size() != 1) error("Sample ${id}: conflicting ${stage}.${key} results for ${haplotype}.")
                        [(key): paths[0]]
                    }
                    merged ? [(stage): merged] : [:]
                }
                [(haplotype): stages]
            }
            def meta = metas[0] - metas[0].subMap('haplotype', 'assembly', 'assembly_map_bam', 'polished', 'scaffolds',
                'scaffolds_hic', 'scaffolds_ragtag', 'scaffolds_links', 'scaffolds_longstitch',
                'bwamem_idx', 'hic_dedup_bam', 'hic_dedup_bai', 'hic_genome_idx')
            [meta: meta + [haplotypes: haplotypes, haplotype_results: results]]
        }
        .mix(branched.unphased)

    emit:
    samples
}
