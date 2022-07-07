nextflow.enable.dsl = 2

import org.yaml.snakeyaml.Yaml

include { SAMTOOLS_FASTQ } from "../../modules/nf-core/modules/samtools/fastq/main"

/*
    Input format descriptions

    Simple: TSV ( splitCsv cannot handle embedded commas )
    Flexible: YAML
    ( See Notes: at bottom for implementation details )

    Simple Format:

    ```tsv
    sample_id   data_type   sequences
    sample_A    HiFi   /path/to/hifi/reads.bam
    sample_A    Illumina    /path/to/illumina/reads{1,2}.fastq.gz
    ```

    Flexible Format:
    - Mandatory fields [ 'sample' ]
    - Optional fields [ 'assembly', 'hic', 'hifi', 'rnaseq', 'isoseq' ]

    ```yaml
    samples:
        - id: Sample_A
        assembly:
            - id: Sample_A_HiFi_haps
            pri_asm: '/path/to/primary/assembly'
            alt_asm: '/path/to/alternate/assembly'
            - id: Sample_A_IPA_primary
            pri_asm: '/path/to/primary/assembly'
        hi-c:
            - '/path/to/reads'
            - '/path/to/reads'
        hifi:
            - '/path/to/reads'
            - '/path/to/reads'
    - id: Sample_B
    tools:
        # Something here
    ```
*/

workflow PREPARE_INPUT {

    take:
    infile

    main:
    // Read in sample files
    Channel.fromPath( infile, checkIfExists: true )
        .branch { file ->
            tsv_ch: file.toString().endsWith(".tsv")
            yml_ch: file.toString().endsWith(".yml") || file.toString().endsWith(".yaml")
        }.set { input }

    // Process TSV files
    input.tsv_ch.splitCsv( header: ['sample_id', 'datatype', 'sequences'], skip: 1, sep: '\t' )
        .branch { record -> def seqs = file( record.sequences, checkIfExists: true)
            // If seqs is not a list, it is the absolute path to a file.
            // If seqs is a List, they do not preserve glob order and are relative paths.
            if ( seqs instanceof List ) {
                seqs = seqs.sort() { it.toString() }
            }
            hic_ch      : record.datatype == 'hic'
                return [ [ id: record.sample_id ], seqs ]
            hifi_ch     : record.datatype == 'hifi'
                return [ [ id: record.sample_id ], seqs ]
            ont_ch      : record.datatype == 'ont'
                return [ [ id: record.sample_id ], seqs ]
            illumina_ch : record.datatype == 'illumina'
                return [ [ id: record.sample_id ], seqs ]
            rnaseq_ch   : record.datatype == 'rnaseq'
                return [ [ id: record.sample_id ], seqs ]
            isoseq_ch   : record.datatype == 'isoseq'
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
        .multiMap { data ->
            assembly_ch : data.assembly ? [ data.id, data.assembly ] : []
            hic_ch      : data.hic      ? [ data.id, data.hic.collect { file( it, checkIfExists: true ) } ] : []
            hifi_ch     : data.hifi     ? [ data.id, data.hifi.collect { file( it, checkIfExists: true ) } ] : []
            ont_ch      : data.ont      ? [ data.id, data.ont.collect { file( it, checkIfExists: true ) } ] : []
            illumina_ch : data.illumina ? [ data.id, data.illumina.collect{ file( it, checkIfExists: true ) } ] : []
            rnaseq_ch   : data.rnaseq   ? [ data.id, data.rnaseq.collect { file( it, checkIfExists: true ) } ] : []
            isoseq_ch   : data.isoseq   ? [ data.id, data.isoseq.collect { file( it, checkIfExists: true ) } ] : []
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
                    alt_asm: ( assembly.alt_asm ? file( assembly.alt_asm, checkIfExists: true ) : null )
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
        .groupTuple()
        .set { hifi_fastx_ch }

    emit:
    assemblies = assembly_ch
    hic        = yml_input.hic_ch.filter { !it.isEmpty() }.mix( tsv_input.hic_ch ).groupTuple()
    hifi       = hifi_fastx_ch
    ont        = yml_input.ont_ch.filter { !it.isEmpty() }.mix( tsv_input.ont_ch ).groupTuple()
    illumina   = yml_input.illumina_ch.filter { !it.isEmpty() }.mix( tsv_input.illumina_ch ).groupTuple()
    rnaseq     = yml_input.rnaseq_ch.filter { !it.isEmpty() }.mix( tsv_input.rnaseq_ch ).groupTuple()
    isoseq     = yml_input.isoseq_ch.filter { !it.isEmpty() }.mix( tsv_input.isoseq_ch ).groupTuple()
}

def readYAML( yamlfile ) {
    // TODO: Validate sample file
    return new Yaml().load( new FileReader( yamlfile.toString() ) )
}

/*
Notes:

YAML file structured as above results in the following nested structure.

```
[
    samples:[
        [
            id:Sample_A,
            assembly:[
                [
                    id:Sample_A_HiFi_haps,
                    pri_asm:/path/to/primary/assembly,
                    alt_asm:/path/to/alternate/assembly
                ],
                [
                    id:Sample_A_IPA_primary,
                    pri_asm:/path/to/primary/assembly
                ]
            ],
            hi-c:[
                /path/to/reads,
                /path/to/reads
            ],
            hifi:[
                /path/to/reads,
                /path/to/reads
            ]
        ],
        [
            id:Sample_B
        ]
    ],
    tools: ''
]
```
*/
