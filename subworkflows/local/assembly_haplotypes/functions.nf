// Sample identity stays stable; assembly joins distinguish the haplotype as well.
def createHaplotypeKey(meta) {
    meta.haplotype ? [meta.id, meta.haplotype] : [meta.id]
}
