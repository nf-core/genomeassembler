include { LIMA } from '../../modules/lima/main'
include { SAMTOOLS_FASTQ as TO_FASTQ } from '../../modules/samtools/fastq/main'

workflow PREPARE_HIFI {
  take: inputs

  main:
    inputs
      .map { it -> [it.sample, it.hifireads] }
      .set { hifireads }
    if(params.lima) {
      if(is.null(params.pacbio_primers)) error 'Trimming with lima requires a file containing primers (--pacbio_primers)'
      LIMA(hifireads, params.pacbio_primers)
      TO_FASTQ(LIMA.out.bam)
      TO_FASTQ
        .out
        .set { hifireads }
    }

  emit:
      hifireads
}