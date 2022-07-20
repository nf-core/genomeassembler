nextflow.enable.dsl = 2

import org.yaml.snakeyaml.Yaml

include { SAMTOOLS_FASTQ } from "../../modules/nf-core/modules/samtools/fastq/main"

/*
    Input format descriptions

    Note: File paths must not be globs, since URI file globbing is not supported ( and breaks splitCsv when using {,} )

    Simple: CSV or TSV
    Flexible: YAML
    ( See Notes: at bottom for implementation details )

    Simple Format:

    ```tsv
    sample_id   data_type   read1   read2
    sample_A    HiFi   /path/to/hifi/reads.bam
    sample_A    Illumina    /path/to/illumina/read1.fastq.gz    /path/to/illumina/read1.fastq.gz
    ```

    Flexible Format:
    - Mandatory fields [ 'sample' ]
    - Optional fields [ 'assembly', 'hic', 'hifi', 'rnaseq', 'isoseq' ]

    ```yaml
    samples:
      - id: Sample_A
        assembly:
          - id: Sample_A_phased_diploid
            pri_asm: '/path/to/assembly/hap1.fasta'
            pri_gfa: '/path/to/assembly/hap1.gfa'
            alt_asm: '/path/to/assembly/hap2.fasta'
            alt_gfa: '/path/to/assembly/hap2.gfa'
          - id: Sample_A_consensus_haploid
            pri_asm: '/path/to/assembly/consensus.fasta'
        hi-c:
          - read1: '/path/to/read1.fastq.gz'
            read2: '/path/to/read2.fastq.gz'
        hifi:
          - reads: '/path/to/reads.bam'
          - reads: '/path/to/reads.fastq.gz'
        isoseq:
          - reads: '/path/to/reads.bam'
      - id: Sample_B
        ont:
          - chemistry: 'R10.4'
            reads: '/path/to/reads.fastq.gz'
        illumina:
          - read1: '/path/to/read1.fastq.gz'
            read2: '/path/to/read2.fastq.gz'
          - reads: '/path/to/reads.fastq.gz'
        rnaseq:
          - read1: '/path/to/read1.fastq.gz'
            read2: '/path/to/read2.fastq.gz'
          - reads: '/path/to/reads.fastq.gz'
    tools:
        # Something here
    ```
*/

workflow PREPARE_INPUT {

    take:
    ch_input

    main:
    // Read in sample files
    //Channel.fromPath( infile, checkIfExists: true )
    ch_input.branch { file ->
            csv_ch: file.name.endsWith(".csv")
            tsv_ch: file.name.endsWith(".tsv")
            yml_ch: file.name.endsWith(".yml") || file.name.endsWith(".yaml")
        }.set { input }

    // Process CSV files
    input.csv_ch.splitCsv( header: ['sample_id', 'datatype', 'read1', 'read2'], skip: 1, sep: ',' )
        .set { csv_records }

    // Process TSV files
    input.tsv_ch.splitCsv( header: ['sample_id', 'datatype', 'read1', 'read2'], skip: 1, sep: '\t' )
        .mix( csv_records )
        .branch { record -> def seqs = record.read2 ? [ file( record.read1, checkIfExists: true ), file( record.read2, checkIfExists: true ) ] : file( record.read1, checkIfExists: true )
            hic_ch      : record.datatype.toLowerCase() == 'hic'
                return [ [ id: record.sample_id ], seqs ]
            hifi_ch     : record.datatype.toLowerCase() == 'hifi'
                return [ [ id: record.sample_id ], seqs ]
            ont_ch      : record.datatype.toLowerCase() == 'ont'
                return [ [ id: record.sample_id ], seqs ]
            illumina_ch : record.datatype.toLowerCase() == 'illumina'
                return [ [ id: record.sample_id ], seqs ]
            rnaseq_ch   : record.datatype.toLowerCase() == 'rnaseq'
                return [ [ id: record.sample_id ], seqs ]
            isoseq_ch   : record.datatype.toLowerCase() == 'isoseq'
                return [ [ id: record.sample_id ], seqs ]
        }.set { tsv_input }

    // Process YAML files
    input.yml_ch
        .map { file -> readYAML( file ) }
        .multiMap { file ->
            samples_ch: file.samples
            tools_ch: file.tools
        }
        .set { ymlfile }

    ymlfile.samples_ch
        .flatten()
        .dump( tag: 'YAML Samples' )
        .multiMap { data ->
            assembly_ch : ( data.assembly ? [ [ id: data.id ], data.assembly ] : [] )
            hic_ch      : ( data.hic      ? [ [ id: data.id ], data.hic.collect { [ file( it.read1, checkIfExists: true ), file( it.read2, checkIfExists: true ) ] } ] : [] )
            hifi_ch     : ( data.hifi     ? [ [ id: data.id ], data.hifi.collect { file( it.reads, checkIfExists: true ) } ] : [] )
            ont_ch      : ( data.ont      ? [ [ id: data.id ], data.ont.collect { file( it.reads, checkIfExists: true ) } ] : [] )
            illumina_ch : ( data.illumina ? [ [ id: data.id ], data.illumina.collect{ it.reads ? file( it.reads, checkIfExists: true ) : [ file( it.read1, checkIfExists: true ), file( it.read2, checkIfExists: true ) ] } ] : [] )
            rnaseq_ch   : ( data.rnaseq   ? [ [ id: data.id ], data.rnaseq.collect { it.reads ? file( it.reads, checkIfExists: true ) : [ file( it.read1, checkIfExists: true ), file( it.read2, checkIfExists: true ) ] } ] : [] )
            isoseq_ch   : ( data.isoseq   ? [ [ id: data.id ], data.isoseq.collect { file( it.reads, checkIfExists: true ) } ] : [] )
        }
        .set{ yml_input }

    // Convert assembly filename to files for correct staging
    yml_input.assembly_ch
        .filter { !it.isEmpty() }
        .transpose()     // Data is [ sample, [ id:'assemblerX_build1', pri_asm: '/path/to/primary_asm', alt_asm: '/path/to/alternate_asm' ]]
        .map { sample, assembly ->
            [
                sample,
                [
                    id: assembly.id,
                    pri_asm: file( assembly.pri_asm, checkIfExists: true ),
                    alt_asm: ( assembly.alt_asm ? file( assembly.alt_asm, checkIfExists: true ) : null ),
                    pri_gfa: ( assembly.pri_gfa ? file( assembly.pri_gfa, checkIfExists: true ) : null ),
                    alt_gfa: ( assembly.alt_gfa ? file( assembly.alt_gfa, checkIfExists: true ) : null )
                ]
            ]
        }
        .set { assembly_ch }

    // Convert HiFi BAMS to FastQ
    yml_input.hifi_ch
        .filter { !it.isEmpty() }
        .mix( tsv_input.hifi_ch )
        .transpose()   // Transform to [ [ id: 'sample_name'], file('/path/to/read')  ]
        .map { meta, filename -> [ [ id: meta.id, single_end: true ], filename ] } // Necessary for correct nf-core samtools/fastq use
        .branch { meta, filename ->
            bam_ch: filename.toString().endsWith(".bam")
            fastx_ch: true // assume everything else is fastx
        }.set { hifi }
    SAMTOOLS_FASTQ ( hifi.bam_ch )  // TODO: Swap to fasta to save space?
    hifi.fastx_ch.mix( SAMTOOLS_FASTQ.out.fastq )
        .map { meta, filename -> [ [ id: meta.id ], filename ] } // Remove single_end flag
        .set { hifi_fastx_ch }

    emit:
    assemblies = assembly_ch.dump( tag: 'Input: Assemblies' )
    hic        = yml_input.hic_ch.filter { !it.isEmpty() }.transpose().mix( tsv_input.hic_ch ).dump( tag: 'Input: Hi-C' )
    hifi       = hifi_fastx_ch.dump( tag: 'Input: PacBio HiFi' )
    ont        = yml_input.ont_ch.filter { !it.isEmpty() }.transpose().mix( tsv_input.ont_ch ).dump( tag: 'Input: ONT' )
    illumina   = yml_input.illumina_ch.filter { !it.isEmpty() }.transpose().mix( tsv_input.illumina_ch ).dump( tag: 'Input: Illumina' )
    rnaseq     = yml_input.rnaseq_ch.filter { !it.isEmpty() }.transpose().mix( tsv_input.rnaseq_ch ).dump( tag: 'Input: Illumina RnaSeq' )
    isoseq     = yml_input.isoseq_ch.filter { !it.isEmpty() }.transpose().mix( tsv_input.isoseq_ch ).dump( tag: 'Input: PacBio IsoSeq' )
}

def readYAML( yamlfile ) {
    // TODO: Validate sample file
    return new Yaml().load( new FileReader( yamlfile.toString() ) )
}

/*
Notes:

Use
```
nextflow run main.nf -profile test_input_yml,docker -resume -dump-channels 'YAML Samples' -ansi-log false
```
To see the YAML structure.


Use
```
nextflow run main.nf -profile test_input_yml,docker -resume -dump-channels 'Input: *' -ansi-log false
```
to see the different channel outputs
*/
