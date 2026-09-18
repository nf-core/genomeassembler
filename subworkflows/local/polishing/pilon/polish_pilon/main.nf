include { PILON } from '../../../../../modules/nf-core/pilon/main'
include { MAP_SR } from '../../../mapping/map_sr/main'
include { LIFTOFF } from '../../../../../modules/nf-core/liftoff/main'
include { QC } from '../../../qc/main.nf'
include { HTSLIB_BGZIPTABIX as UNZIP } from '../../../../../modules/nf-core/htslib/bgziptabix/main'
include { HTSLIB_REBGZIP as BGZIP } from '../../../../../modules/local/htslib/rebgzip/main'


workflow POLISH_PILON {
    take:
    ch_main
    meryl_kmers

    main:

    map_sr_in = ch_main
        .multiMap {
            it ->
            shortreads: [it.meta, it.meta.shortreads]
            assembly: [
                it.meta,
                it.meta.polish == "medaka+pilon" ? it.meta.polished.medaka : it.meta.polish == "dorado+pilon" ? it.meta.polished.dorado : it.meta.assembly
                ]
        }

    MAP_SR(map_sr_in.shortreads, map_sr_in.assembly)

    ch_to_zip = map_sr_in.assembly.map {
        meta, assembly ->
        [
            meta,
            assembly,
            [],
            []
        ]
    }

    UNZIP(ch_to_zip, "decompress", false, "fasta")
    // Update meta
    pilon_ref = UNZIP.out.output


    pilon_in = pilon_ref
        .join(MAP_SR.out.aln_to_assembly_bam_bai)
        .multiMap {
            meta, assembly, bam, bai ->
            assembly: [meta, assembly]
            bam_bai: [meta, bam, bai]
        }

    PILON(
        pilon_in.assembly,
        pilon_in.bam_bai,
        "bam",
    )

    BGZIP(PILON.out.improved_assembly)

    pilon_polished = BGZIP.out.bgzipped

    ch_main = pilon_polished
        .map { meta, polished_pilon -> [ meta: meta + [ polished: [pilon: polished_pilon] ] ]  }

    QC(ch_main.map { it -> [meta: it.meta - it.meta.subMap("assembly_map_bam") + [assembly_map_bam: null] ]},
        pilon_polished.map {meta, polished -> [meta.id, polished ]},
        meryl_kmers)

    liftoff_in = ch_main
        .filter {
            it -> it.meta.lift_annotations
        }
        .map { it ->
                [
                it.meta,
                it.meta.polished.pilon,
                it.meta.ref_fasta,
                it.meta.ref_gff
                ]
        }

    LIFTOFF(liftoff_in, [])

    emit:
    ch_main
    quast_out               = QC.out.quast_out
    busco_out               = QC.out.busco_out
    merqury_report_files    = QC.out.merqury_report_files
}
