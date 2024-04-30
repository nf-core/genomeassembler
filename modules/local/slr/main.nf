include { initOptions; saveFiles; getSoftwareName } from './functions'

params.options = [:]
options        = initOptions(params.options)

process SLR {
  tag "$meta"
  label 'process_high'
  
  container "gitlab.lrz.de:5005/beckerlab/container-playground/slr:8878afbd"

  publishDir "${params.out}",
      mode: params.publish_dir_mode,
      saveAs: { filename -> saveFiles(filename:filename,
                                      options:params.options, 
                                      publish_dir:"${task.process}".replace(':','/').toLowerCase(), 
                                      publish_id:meta) }
  input:
      tuple val(meta), path(assembly), path(reads)
  
  
  output:
      tuple val(meta), path("${meta}_slr_scaffold.fa"), emit: scaffolds
      tuple val(meta), path("${meta}_slr_unique.fa"),   emit: unique_contigs
      tuple val(meta), path("${meta}_slr_ambigous.fa"), emit: abigous_contigs
  
  script:
      def prefix = task.ext.prefix ?: "${meta}"
  """
  bwa index ${assembly}
  bwa mem -a ${assembly} ${assembly} > ${meta}_contigs_self.sam
  samtools view -Sb ${meta}_contigs_self.sam > ${meta}_contigs_self.bam
  bwa mem -t$task.cpus -k11 -W20 -r10 -A1 -B1 -O1 -E1 -L0 -a -Y ${assembly} ${reads} > ${meta}_realigned.sam
  samtools view -Sb ${meta}_realigned.sam > ${meta}_realigned.bam
  SLR -c ${assembly} -r ${meta}_realigned.bam -d ${meta}_contigs_self.sam -p ${meta}_out

  cp ${meta}_out/scaffold_set.fa ${meta}_slr_scaffold.fa
  cp ${meta}_out/unique-contig-set.fa ${meta}_slr_unique.fa
  cp ${meta}_out/ambiguous-contig-set.fa ${meta}_slr_ambigous.fa
  """
}