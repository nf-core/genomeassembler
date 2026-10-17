// Preserve retained assembly stages when another polishing step is added.
def addPolishedAssembly(meta, stage, assembly) {
    def polished = meta.polished ?: [:]
    if (polished.polished_dorado) {
        polished = polished - polished.subMap('polished_dorado') + [dorado: polished.polished_dorado]
    }
    return meta + [polished: polished + [(stage): assembly]]
}
