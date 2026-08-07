include { RAGTAG_SCAFFOLD } from '../../../../modules/nf-core/ragtag/scaffold/main'
include { QC } from '../../qc/main'
include { LIFTOFF } from '../../../../modules/nf-core/liftoff/main'
include { HTSLIB_REBGZIP as BGZIP } from '../../../../modules/local/htslib/rebgzip/main'

workflow RUN_RAGTAG {
    take:
    ch_main
    meryl_kmers

    main:
    ragtag_in = ch_main
        .multiMap { it ->
                    def assembly_to_scaffold =
                                it.meta.scaffold ?
                                (
                                    it.meta.scaffolds_hic ?:
                                    it.meta.scaffolds_longstitch ?:
                                    it.meta.scaffolds_links
                                ) :
                                it.meta.polished ?
                                (
                                    it.meta.polished.pilon ?:
                                    it.meta.polished.medaka ?:
                                    it.meta.polished.dorado
                                ) :
                                it.meta.assembly
                    assembly:
                        [
                            it.meta,
                            assembly_to_scaffold
                        ]
                    reference:
                        [
                            it.meta,
                            it.meta.ref_fasta
                        ]
                    }

    ragtag_in.assembly.dump(tag: "SCAFFOLD: RAGTAG: Assembly inputs")
    ragtag_in.reference.dump(tag: "SCAFFOLD: RAGTAG: Reference inputs")

    RAGTAG_SCAFFOLD(ragtag_in.assembly, ragtag_in.reference, [[], []], [[], [], []])

    BGZIP(RAGTAG_SCAFFOLD.out.corrected_assembly)

    ch_main_scaffolded = BGZIP.out.bgzipped
        .map { meta, corrected -> [meta: meta + [ scaffolds_ragtag: corrected] ] }

    liftoff_in = ch_main_scaffolded
        .filter {
            it -> it.meta.lift_annotations
        }
        .map { it ->
                [
                it.meta,
                it.meta.scaffolds_ragtag,
                it.meta.ref_fasta,
                it.meta.ref_gff
                ]
        }

    LIFTOFF(liftoff_in, [])

    QC(ch_main_scaffolded.map { it -> [meta: it.meta - it.meta.subMap("assembly_map_bam") + [assembly_map_bam: null] ] },
        BGZIP.out.bgzipped.map { meta, corrected -> [ meta.id, corrected ] },
        meryl_kmers)

    emit:
    ch_main
    quast_out               = QC.out.quast_out
    busco_out               = QC.out.busco_out
    merqury_report_files    = QC.out.merqury_report_files
}
