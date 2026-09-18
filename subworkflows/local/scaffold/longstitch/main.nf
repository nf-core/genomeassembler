include { LONGSTITCH } from '../../../../modules/nf-core/longstitch/main'
include { QC } from '../../qc/main'
include { LIFTOFF } from '../../../../modules/nf-core/liftoff/main'
include { HTSLIB_REBGZIP as BGZIP } from '../../../../modules/local/htslib/rebgzip/main'

workflow RUN_LONGSTITCH {
    take:
    ch_main
    meryl_kmers

    main:
    ch_versions = channel.empty()

    longstitch_in = ch_main
        .multiMap {
            it ->
            assembly: [
                it.meta,
                it.meta.polished ?
                    (
                        it.meta.polished.pilon  ?:
                        it.meta.polished.medaka ?:
                        it.meta.polished.dorado
                    ) :
                    it.meta.assembly
                ]
            reads: [it.meta, it.meta.qc_reads_path]
            command: "tigmint-ntLink-arks"
            span: []
            genomesize: it.meta.genome_size
            longmap: it.qc_reads
        }

    //longstitch_in.dump(tag: "SCAFFOLD: LONGSTITCH: inputs")

    LONGSTITCH(longstitch_in.assembly, longstitch_in.reads, longstitch_in.command, longstitch_in.span, longstitch_in.genomesize, longstitch_in.longmap)

    BGZIP(LONGSTITCH.out.tigmint_ntLink_arcs_fasta)

    ch_main_scaffolded = BGZIP.out.bgzipped
        .map { meta, scaff_longst -> [meta: meta + [scaffolds_longstitch: scaff_longst] ] }

    liftoff_in = ch_main_scaffolded
        .filter {
            it -> it.meta.lift_annotations
        }
        .map { it ->
                [
                it.meta,
                it.meta.scaffolds_longstitch,
                it.meta.ref_fasta,
                it.meta.ref_gff
                ]
        }

    LIFTOFF(liftoff_in,[])

    QC( ch_main_scaffolded.map { it -> [ meta: it.meta - it.meta.subMap("assembly_map_bam") + [assembly_map_bam: null] ] },
        BGZIP.out.bgzipped.map { meta, scaffold -> [meta.id, scaffold]},
        meryl_kmers)

    emit:
    ch_main                 = ch_main_scaffolded
    quast_out               = QC.out.quast_out
    busco_out               = QC.out.busco_out
    merqury_report_files    = QC.out.merqury_report_files
    versions                = ch_versions
}
