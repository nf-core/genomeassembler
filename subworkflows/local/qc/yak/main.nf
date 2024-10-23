include { KMER_ASSEMBLY } from '../../../../modules/local/yak/main'
include { KMER_HISTOGRAM as KMER_ASSEMBLY_HIST} from '../../../../modules/local/yak/main'
include { ASSEMBLY_KQV as KMER_ASSEMBLY_QV } from '../../../../modules/local/yak/main'

workflow YAK_QC {
  take:
    assembly
    kmer_shortreads

  main:
    if(params.yak) {
      KMER_ASSEMBLY(assembly)
      KMER_ASSEMBLY_HIST(KMER_ASSEMBLY.out)
      if(params.short_reads) {
          KMER_ASSEMBLY
              .out
              .join(kmer_shortreads)
              .set{ yak_qv_in }
          KMER_ASSEMBLY_QV(yak_qv_in)
      }
    }
 }