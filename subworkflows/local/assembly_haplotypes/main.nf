// Sample identity stays stable; assembly joins distinguish the haplotype as well.
def createHaplotypeKey(meta) {
    meta.haplotype ? [meta.id, meta.haplotype] : [meta.id]
}

def createHaplotypePrefix(meta) {
    meta.haplotype ? "${meta.id}_${meta.haplotype}" : "${meta.id}"
}

// Collect per-assembly task records into one final record per original sample.
// Parallel scaffold branches can repeat an initial assembly and polishing paths;
// merge equal paths, retain different stages, and reject conflicting paths for
// the same stage/haplotype rather than silently discarding a branch's result.
workflow COLLATE_HAPLOTYPES {
    take:
    assemblies

    main:
    assemblies_by_phasing = assemblies.branch { row ->
        phased: row.meta.haplotype != null
        unphased: true
    }
    samples = assemblies_by_phasing.phased
        .map { row -> [row.meta.id, row.meta] }
        .groupTuple()
        .map { id, metas ->
            def by_haplotype = metas.groupBy { meta -> meta.haplotype }
            if (by_haplotype.keySet() != ['hap1', 'hap2'].toSet()) {
                error("Sample ${id}: expected assemblies for both hap1 and hap2.")
            }
            // Hifiasm normally emits one file per haplotype. This checks metadata
            // consistency across downstream branches, not hifiasm file multiplicity.
            def haplotypes = by_haplotype.collectEntries { haplotype, metamaps ->
                def files = metamaps*.assembly.unique()
                if (files.size() != 1) {
                    error("Sample ${id}: conflicting initial assemblies for ${haplotype}.")
                }
                [(haplotype): files[0]]
            }
            def results = by_haplotype.collectEntries { haplotype, metamaps ->
                def stages = ['polished', 'scaffolds'].collectEntries { stage ->
                    def entries = metamaps.collectMany { meta -> (meta[stage] ?: [:]).entrySet().toList() }.groupBy { entry -> entry.key }
                    def merged = entries.collectEntries { key, values ->
                        def paths = values*.value.unique()
                        if (paths.size() != 1) {
                            error("Sample ${id}: conflicting ${stage}.${key} results for ${haplotype}.")
                        }
                        [(key): paths[0]]
                    }
                    merged ? [(stage): merged] : [:]
                }
                [(haplotype): stages]
            }
            def meta = metas[0] - metas[0].subMap(
                'haplotype',
                'assembly',
                'assembly_map_bam',
                'polished',
                'scaffolds',
                'scaffolds_hic',
                'scaffolds_ragtag',
                'scaffolds_links',
                'scaffolds_longstitch',
                'bwamem_idx',
                'hic_dedup_bam',
                'hic_dedup_bai',
                'hic_genome_idx',
            )
            [meta: meta + [haplotypes: haplotypes, haplotype_results: results]]
        }
        .mix(assemblies_by_phasing.unphased)

    emit:
    samples
}
