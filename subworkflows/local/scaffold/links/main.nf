include { LINKS } from '../../../../modules/nf-core/links/main'
include { QC } from '../../qc/main'
include { LIFTOFF } from '../../../../modules/nf-core/liftoff/main'
include { HTSLIB_REBGZIP as BGZIP } from '../../../../modules/local/htslib/rebgzip/main'

workflow RUN_LINKS {
    take:
    ch_main
    meryl_kmers

    main:
    ch_main.dump(tag: "SCAFFOLD: LINKS: WORKFLOW inputs")
    links_in = ch_main
        .multiMap { it ->
            assembly:   [it.meta, it.meta.polished ? (it.meta.polished.pilon ?: it.meta.polished.medaka ?: it.meta.polished.dorado) : it.meta.assembly]
            reads:      [it.meta, it.meta.qc_reads_path]
        }

    links_in.assembly.dump(tag: "SCAFFOLD: LINKS: Assembly inputs")
    links_in.reads.dump(tag: "SCAFFOLD: LINKS: Read inputs")

    LINKS(links_in.assembly, links_in.reads)

    BGZIP(LINKS.out.scaffolds_fasta)

    ch_main_scaffolded = BGZIP.out.bgzipped
        .map { meta, scaff_links -> [meta: meta + [scaffolds_links: scaff_links] ] }

    QC(ch_main_scaffolded.map { it -> [meta: it.meta - it.meta.subMap("assembly_map_bam") + [assembly_map_bam: null] ]},
        BGZIP.out.bgzipped.map { meta, scaffold -> [meta.id, scaffold]},
         meryl_kmers)

    liftoff_in = ch_main_scaffolded
        .filter {
            it -> it.meta.lift_annotations
        }
        .map { it ->
                [
                it.meta,
                it.meta.scaffolds_links,
                it.meta.ref_fasta,
                it.meta.ref_gff
                ]
        }

    LIFTOFF(liftoff_in, [])

    emit:
    ch_main                 = ch_main_scaffolded
    quast_out               = QC.out.quast_out
    busco_out               = QC.out.busco_out
    merqury_report_files    = QC.out.merqury_report_files
}
