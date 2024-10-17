include { COUNT } from '../../modules/jellyfish/main'
include { DUMP } from '../../modules/jellyfish/main'
include { HISTO } from '../../modules/jellyfish/main'
include { STATS } from '../../modules/jellyfish/main'
include { GENOMESCOPE } from '../../modules/genomescope/main'

workflow JELLYFISH {
  take:
    samples // id, fasta
    nanoq_out
  
  main: 
    COUNT(samples)
    COUNT
      .out
      .set { kmers }

    if(params.dump) {
      DUMP(kmers)
    }    

    HISTO(kmers)

    if(!params.read_length == null) {
      HISTO
      .out
      .map { it -> [it[0], it[1], params.kmer_length, params.read_length] }
      .set { genomescope_in }
    } 

    if(params.read_length == null) {
      HISTO
      .out
      .map { it -> [it[0], it[1], params.kmer_length] }
      .join( nanoq_out )
      .set { genomescope_in }
    }

    GENOMESCOPE(genomescope_in)

    STATS(kmers)

    GENOMESCOPE.out.estimated_hap_len
      .set{ hap_len }    
      
  emit:
   hap_len
}