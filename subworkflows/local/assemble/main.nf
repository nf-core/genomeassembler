include { FLYE } from '../../../modules/nf-core/flye/main'
include { HIFIASM } from '../../../modules/nf-core/hifiasm/main'
include { HIFIASM as HIFIASM_ONT } from '../../../modules/nf-core/hifiasm/main'
include { GFA_2_FA } from '../../../modules/local/gfa2fa/main'
include { MAP_TO_ASSEMBLY } from '../mapping/map_to_assembly/main'
include { MAP_TO_REF } from '../mapping/map_to_ref/main'
include { RUN_QUAST } from '../qc/quast/main'
include { RUN_BUSCO } from '../qc/busco/main'
include { MERQURY_QC } from '../qc/merqury/main'
include { RUN_LIFTOFF } from '../liftoff/main'
include { RAGTAG_SCAFFOLD } from '../../../modules/local/ragtag/main'


workflow ASSEMBLE {
    take:
    ont_reads // meta, reads
    hifi_reads // meta, reads
    ch_input
    genomescope_out
    meryl_kmers

    main:
    // Empty channels
    Channel.empty().set { ch_refs }
    Channel.empty().set { ch_ref_bam }
    Channel.empty().set { ch_assembly_bam }
    Channel.empty().set { ch_assembly }
    Channel.empty().set { assembly_quast_reports }
    Channel.empty().set { assembly_busco_reports }
    Channel.empty().set { assembly_merqury_reports }
    Channel.empty().set { flye_inputs }
    Channel.empty().set { hifiasm_inputs }
    Channel.empty().set { longreads }
    Channel.empty().set { ch_versions }

    if (params.use_ref) {
        ch_input
            .map { row -> [row.meta, row.ref_fasta] }
            .set { ch_refs }
    }

    if (params.skip_assembly) {
        // Sample sheet layout when skipping assembly
        // sample,ontreads,assembly,ref_fasta,ref_gff
        ch_input
            .map { row -> [row.meta, row.assembly] }
            .set { ch_assembly }
    }
    if (!params.skip_assembly) {
        def hifi_only = params.hifi && !params.ont ? true : false
        // Define inputs for flye
        if (params.assembler == "flye") {
            if (params.hifi) {
                hifi_reads
                    .map { it -> [it[0], it[1]] }
                    .set { flye_inputs }
            }
            if (params.ont) {
                ont_reads.set { flye_inputs }
                if (params.genome_size == null && params.jellyfish) {
                    params.genome_size = genomescope_out
                }
            }
            // Run flye
            FLYE(flye_inputs, params.flye_mode)
            FLYE.out.fasta.set { ch_assembly }
            ch_versions = ch_versions.mix(FLYE.out.versions)
        }
        if (params.assembler == "hifiasm") {
            // HiFi and ONT reads in ultralong mode
            if (params.hifi && params.ont) {
                hifi_reads
                    .join(ont_reads)
                    .set { hifiasm_inputs }
                HIFIASM(hifiasm_inputs, [[], [], []], [[], [], []])
                GFA_2_FA(HIFIASM.out.processed_contigs)
                GFA_2_FA.out.contigs_fasta.set { ch_assembly }

                ch_versions = ch_versions.mix(HIFIASM.out.versions).mix(GFA_2_FA.out.versions)
            }
            // ONT reads only
            if (!params.hifi && params.ont) {
                ont_reads
                    .map { meta, ontreads -> [meta, ontreads, []] }
                    .set { hifiasm_inputs }
                HIFIASM_ONT(hifiasm_inputs, [[], [], []], [[], [], []])
                GFA_2_FA(HIFIASM_ONT.out.processed_contigs)
                GFA_2_FA.out.contigs_fasta.set { ch_assembly }

                ch_versions = ch_versions.mix(HIFIASM_ONT.out.versions).mix(GFA_2_FA.out.versions)
            }
            // HiFI reads only
            if (params.hifi && !params.ont) {
                hifi_reads
                    .map { meta, ontreads -> [meta, ontreads, []] }
                    .set { hifiasm_inputs }
                HIFIASM(hifiasm_inputs, [[], [], []], [[], [], []])

                GFA_2_FA(HIFIASM.out.processed_contigs)
                GFA_2_FA.out.contigs_fasta.set { ch_assembly }

                ch_versions = ch_versions.mix(HIFIASM.out.versions).mix(GFA_2_FA.out.versions)
            }
        }
        if (params.assembler == "flye_on_hifiasm") {
            // Run hifiasm
            hifi_reads
                .map { meta, hifireads -> [meta, hifireads, []] }
                .set { hifiasm_inputs }
            HIFIASM(hifiasm_inputs, [[], [], []], [[], [], []])

            GFA_2_FA(HIFIASM.out.processed_contigs)

            ch_versions = ch_versions.mix(HIFIASM.out.versions).mix(GFA_2_FA.out.versions)

            // Run flye
            ont_reads.set { flye_inputs }
            if (params.genome_size == null && params.jellyfish) {
                params.genome_size = genomescope_out
            }
            FLYE(flye_inputs, params.flye_mode)
            FLYE.out.fasta
                .join(
                    GFA_2_FA.out.contigs_fasta
                )
                .set { ragtag_in }
            RAGTAG_SCAFFOLD(ragtag_in)
            // takes: meta, assembly (flye), reference (hifi)
            RAGTAG_SCAFFOLD.out.corrected_assembly.set { ch_assembly }
            ch_versions = ch_versions.mix(FLYE.out.versions).mix(RAGTAG_SCAFFOLD.out.versions)
        }
    }
    /*
    Prepare alignments
    */
    if (params.skip_alignments) {
        // Sample sheet layout when skipping assembly and mapping
        // sample,ontreads,assembly,ref_fasta,ref_gff,assembly_bam,assembly_bai,ref_bam
        ch_input
            .map { row -> [row.meta, row.ref_bam] }
            .set { ch_ref_bam }

        ch_input
            .map { row -> [row.meta, row.assembly_bam] }
            .set { ch_assembly_bam }
    }
    else {
        Channel.empty().set { ch_ref_bam }
        if (params.assembler == "flye") {
            flye_inputs
                .map { it -> [it[0], it[1]] }
                .set { longreads }
        }
        if (params.assembler == "hifiasm" || params.assembler == "flye_on_hifiasm") {
            hifiasm_inputs
                .map { meta, long_reads, _ultralong -> [meta, long_reads] }
                .set { longreads }
            // When using either hifiasm_ont or flye_on_hifiasm, both reads are available, which should be used for qc?
            if (params.hifi && params.ont) {
                if (params.qc_reads == 'ONT') {
                    ont_reads
                        .map { it -> [it[0], it[1]] }
                        .set { longreads }
                }
                if (params.qc_reads == 'HIFI') {
                    hifi_reads
                        .map { it -> [it[0], it[1]] }
                        .set { longreads }
                }
            }
        }
        if (params.quast) {

            if (params.use_ref) {
                MAP_TO_REF(longreads, ch_refs)

                MAP_TO_REF.out.ch_aln_to_ref_bam.set { ch_ref_bam }
            }

            MAP_TO_ASSEMBLY(longreads, ch_assembly)
            MAP_TO_ASSEMBLY.out.aln_to_assembly_bam.set { ch_assembly_bam }

            RUN_QUAST(ch_assembly, ch_input, ch_ref_bam, ch_assembly_bam)
            RUN_QUAST.out.quast_tsv.set { assembly_quast_reports }

            ch_versions = ch_versions.mix(MAP_TO_ASSEMBLY.out.versions).mix(RUN_QUAST.out.versions)

        }
    }
    /*
    QC on initial assembly
    */
    if (params.busco) {
        RUN_BUSCO(ch_assembly)
        RUN_BUSCO.out.batch_summary.set { assembly_busco_reports }
        ch_versions = ch_versions.mix(RUN_BUSCO.out.versions)
    }

    if (params.short_reads) {
        MERQURY_QC(ch_assembly, meryl_kmers)
        MERQURY_QC.out.stats
            .join(
                MERQURY_QC.out.spectra_asm_hist
            )
            .join(
                MERQURY_QC.out.spectra_cn_hist
            )
            .join(
                MERQURY_QC.out.assembly_qv
            )
            .set { assembly_merqury_reports }

        ch_versions = ch_versions.mix(MERQURY_QC.out.versions)
    }

    if (params.lift_annotations) {
        RUN_LIFTOFF(ch_assembly, ch_input)
        ch_versions = ch_versions.mix(RUN_LIFTOFF.out.versions)
    }

    assembly = ch_assembly
    ref_bam = ch_ref_bam
    versions = ch_versions
    emit:
    assembly
    ref_bam
    longreads
    assembly_quast_reports
    assembly_busco_reports
    assembly_merqury_reports
    versions
}
