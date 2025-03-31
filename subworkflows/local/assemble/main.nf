include { FLYE } from '../../../modules/nf-core/flye/main'
include { HIFIASM } from '../../../modules/nf-core/hifiasm/main'
include { HIFIASM as HIFIASM_ONT } from '../../../modules/nf-core/hifiasm/main'
include { GFA_2_FA } from '../../../modules/local/gfa2fa/main'
include { MAP_TO_REF } from '../mapping/map_to_ref/main'
include { RUN_LIFTOFF } from '../liftoff/main'
include { RAGTAG_PATCH } from '../../../modules/local/ragtag/patch/main'
include { QC } from '../qc/main'


workflow ASSEMBLE {
    take:
    ont_reads // meta, reads
    hifi_reads // meta, reads
    ch_input
    genome_size
    meryl_kmers

    main:
    // Empty channels
    Channel.empty().set { ch_refs }
    Channel.empty().set { ch_ref_bam }
    Channel.empty().set { ch_assembly_bam }
    Channel.empty().set { ch_assembly }
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
            }
            // Run flye
            flye_inputs
                .join(genome_size)
                .map { meta, reads, genomesize -> [meta +[ genome_size: genomesize ], reads] }
                .set { flye_inputs }
            FLYE(flye_inputs, params.flye_mode)
            FLYE.out.fasta.map { meta, assembly -> [meta - meta.subMap('genome_size'), assembly] }.set { ch_assembly }
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
            ont_reads
                .join(genome_size)
                .map { meta, reads, genomesize -> [[id: meta.id, genome_size: genomesize], reads]}
                .set { flye_inputs }

            FLYE(flye_inputs, params.flye_mode)
            FLYE.out.fasta
                .map { meta, assembly -> [[id: meta.id], assembly] }
                .join(
                    GFA_2_FA.out.contigs_fasta
                )
                .set { ragtag_in }
            RAGTAG_PATCH(ragtag_in)
            // takes: meta, assembly (flye), reference (hifi)
            RAGTAG_PATCH.out.patched_fasta.set { ch_assembly }
            ch_versions = ch_versions.mix(FLYE.out.versions).mix(RAGTAG_PATCH.out.versions)
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
                .map { meta, reads -> [[id: meta.id], reads] }
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
        }
    }
    /*
    QC on initial assembly
    */
    QC(ch_input, longreads, ch_assembly, ch_ref_bam, meryl_kmers)
    ch_versions = ch_versions.mix(QC.out.versions)

    if (params.lift_annotations) {
        RUN_LIFTOFF(ch_assembly, ch_input)
        ch_versions = ch_versions.mix(RUN_LIFTOFF.out.versions)
    }

    emit:
    assembly                    = ch_assembly
    ref_bam                     = ch_ref_bam
    longreads
    assembly_quast_reports      = QC.out.quast_out
    assembly_busco_reports      = QC.out.busco_out
    assembly_merqury_reports    = QC.out.merqury_report_files
    versions                    = ch_versions
}
