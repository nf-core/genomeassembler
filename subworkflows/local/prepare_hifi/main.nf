include { LIMA } from '../../../modules/nf-core/lima/main'
include { SAMTOOLS_FASTQ as TO_FASTQ } from '../../../modules/nf-core/samtools/fastq/main'

workflow PREPARE_HIFI {
  take:
  inputs

  main:
  inputs
    .map { it -> [it.meta, it.hifireads] }
    .set { hifireads }
  if (params.lima) {
    if (params.pacbio_primers == null) {
      error('Trimming with lima requires a file containing primers (--pacbio_primers)')
    }
    LIMA(hifireads, params.pacbio_primers)
    TO_FASTQ(LIMA.out.bam, false)
    TO_FASTQ.out.set { hifireads }
  }

  emit:
  hifireads
}
