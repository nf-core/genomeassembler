include { QC                                        } from '../../qc/main'
include { RUN_LIFTOFF                               } from '../../liftoff/main'
include { YAHS                                      } from '../../../../modules/nf-core/yahs/main'
include { HTSLIB_REBGZIP as BGZIP                   } from '../../../../modules/local/htslib/rebgzip/main'
include { BWAMEM2_MEM                               } from '../../../../modules/nf-core/bwamem2/mem/main'
include { BWAMEM2_INDEX                             } from '../../../../modules/nf-core/bwamem2/index/main'
include { SAMTOOLS_FAIDX                            } from '../../../../modules/nf-core/samtools/faidx/main'
include { MINIMAP2_ALIGN as MINIMAP2_HIC            } from '../../../../modules/nf-core/minimap2/align/main'
include { PICARD_MARKDUPLICATES as MARKDUP          } from '../../../../modules/nf-core/picard/markduplicates/main'
include { PICARD_ADDORREPLACEREADGROUPS as ADD_RG   } from '../../../../modules/nf-core/picard/addorreplacereadgroups/main'

workflow HIC {
    take:
    ch_main
    meryl_kmers

    main:

    hic_align_branched = ch_main
        .branch { it ->
            bwamem: it.meta.hic_aligner == "bwa-mem2"
            minimap: it.meta.hic_aligner == "minimap2"
        }

    bwamem_index_in = hic_align_branched
        .bwamem
        .map {
            it ->
            [
                it.meta,
                it.meta.polished ? (it.meta.polished.pilon ?: it.meta.polished.medaka ?: it.meta.polished.dorado) : it.meta.assembly
            ]
        }

    BWAMEM2_INDEX(bwamem_index_in)
    bwamem_mem_in = BWAMEM2_INDEX.out.index
        .map {meta, idx ->
            [meta: meta + [bwamem_idx: idx]]
        }
        .multiMap {
            it ->
            reads: [it.meta, it.meta.hic_reads]
            assembly: [it.meta, it.meta.polished ? (it.meta.polished.pilon ?: it.meta.polished.medaka ?: it.meta.polished.dorado) : it.meta.assembly]
            index:  [it.meta, it.meta.bwamem_idx]
        }

    BWAMEM2_MEM(bwamem_mem_in.reads, bwamem_mem_in.index, bwamem_mem_in.assembly, true)

    minimap2_in = hic_align_branched
        .minimap
        .map { it ->
            [
            it.meta,
            it.meta.hic_reads,
            it.meta.polished ? (it.meta.polished.pilon ?: it.meta.polished.medaka ?: it.meta.polished.dorado) : it.meta.assembly
            ]
        }

    MINIMAP2_HIC(minimap2_in, true, "csi", [], [])

    add_rg_in = BWAMEM2_MEM.out.bam.mix(MINIMAP2_HIC.out.bam)

    ADD_RG(add_rg_in, [[],[]], [[],[]])

    MARKDUP(ADD_RG.out.bam, [[],[]], [[],[]])

    faidx_in = MARKDUP.out.bam
        .map { meta, bam -> [meta.id, meta, bam] }
        .join(
            MARKDUP.out.bai
                .map { meta, bai -> [meta.id, bai] }
        )
        .map {_id, meta, bam, bai -> [meta:meta + [hic_dedup_bam: bam, hic_dedup_bai: bai] ]}
        .map {
            it -> [
            it.meta,
            it.meta.polished ? (it.meta.polished.pilon ?: it.meta.polished.medaka ?: it.meta.polished.dorado) : it.meta.assembly
            ]
        }

    SAMTOOLS_FAIDX(faidx_in, false)

    indexed = SAMTOOLS_FAIDX.out.fai
        .map {
            meta, index ->
            [
                meta: meta + [hic_genome_idx: index]
            ]
        }

    yahs_in = indexed
        .map { it ->
            [
                it.meta,
                it.meta.polished ? (it.meta.polished.pilon ?: it.meta.polished.medaka ?: it.meta.polished.dorado) : it.meta.assembly,
                it.meta.hic_genome_idx,
                it.meta.hic_dedup_bam,
                []
            ]
        }

    YAHS(yahs_in)

    BGZIP(YAHS.out.scaffolds_fasta)

    ch_main_scaffolded = BGZIP.out.bgzipped
        .map { meta, corrected -> [meta: meta + [ scaffolds_hic: corrected] ] }

    liftoff_in = ch_main_scaffolded
        .filter {
            it -> it.meta.lift_annotations
        }
        .map { it ->
                [
                it.meta,
                it.meta.scaffolds_hic,
                it.meta.ref_fasta,
                it.meta.ref_gff
                ]
        }

    RUN_LIFTOFF(liftoff_in)

    QC(ch_main_scaffolded.map { it -> [meta: it.meta - it.meta.subMap("assembly_map_bam") + [assembly_map_bam: null] ] },
        BGZIP.out.bgzipped.map { meta, corrected -> [ meta.id, corrected ] },
        meryl_kmers)

    emit:
    ch_main                 = ch_main_scaffolded
    quast_out               = QC.out.quast_out
    busco_out               = QC.out.busco_out
    merqury_report_files    = QC.out.merqury_report_files
}
