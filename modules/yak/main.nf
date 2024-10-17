process KMER_ASSEMBLY {
    tag "$meta"
    publishDir(
      path: { "${params.out}/yak".replace(':','/').toLowerCase() }, 
      mode: 'copy',
      overwrite: true,
      saveAs: { fn -> fn.substring(fn.lastIndexOf('/')+1) }
    ) 

    input:
    tuple val(meta), path(assembly)

    output:
    tuple val(meta), path("${assembly}.yak")       , emit: assembly_hashes

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    yak count -K1.5g -t$task.cpus -o ${assembly}.yak ${assembly}
    """
}

process KMER_LONGREADS {
    tag "$meta"
    publishDir(
      path: { "${params.out}/yak".replace(':','/').toLowerCase() }, 
      mode: 'copy',
      overwrite: true,
      saveAs: { fn -> fn.substring(fn.lastIndexOf('/')+1) }
    ) 

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("*.yak")       , emit: read_hashes

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    yak count -b37 -t$task.cpus -o ${reads}.yak $reads
    """
}

process KMER_SHORTREADS {
    tag "$meta"
    publishDir(
      path: { "${params.out}/yak".replace(':','/').toLowerCase() }, 
      mode: 'copy',
      overwrite: true,
      saveAs: { fn -> fn.substring(fn.lastIndexOf('/')+1) }
    ) 

    input:
    tuple val(meta), val(paired), path(reads)

    output:
    tuple val(meta), path("*.yak")       , emit: read_hashes

    when:
    task.ext.when == null || task.ext.when

    script:
    input_reads = paired ? "<(zcat ${reads}) <(zcat ${reads})" : "${fastq}"
    """
    yak count -b37 -t$task.cpus -o ${meta}_shortreads.yak $input_reads
    """
}

process READ_QV {
    tag "$meta"
    publishDir(
      path: { "${params.out}/yak".replace(':','/').toLowerCase() }, 
      mode: 'copy',
      overwrite: true,
      saveAs: { fn -> fn.substring(fn.lastIndexOf('/')+1) }
    ) 

    input:
      tuple val(meta), path(longread_yak), path(shortread_yak)

    output:
      tuple val(meta), path("*.kqv.txt"), emit: read_qv

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    name=(basename $longread_yak yak)
    yak inspect $longread_yak $shortread_yak > ${meta}.\$name.longread_shortread.kqv.txt
    """
}
process ASSEMBLY_KQV {
    tag "$meta"
    publishDir(
      path: { "${params.out}/yak".replace(':','/').toLowerCase() }, 
      mode: 'copy',
      overwrite: true,
      saveAs: { fn -> fn.substring(fn.lastIndexOf('/')+1) }
    ) 

    input:
    tuple val(meta), path(assembly_yak), path(shortread_yak)

    output:
    tuple val(meta), path("*.kqv.txt")       , emit: kqv

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    yak inspect $shortread_yak $assembly_yak > ${meta}.assembly_shortread.kqv.txt
    """
}

process KMER_HISTOGRAM {
    tag "$meta"
    publishDir(
      path: { "${params.out}/yak".replace(':','/').toLowerCase() }, 
      mode: 'copy',
      overwrite: true,
      saveAs: { fn -> fn.substring(fn.lastIndexOf('/')+1) }
    ) 

    input:
    tuple val(meta), path(yakfile)

    output:
    tuple val(meta), path("*.hist")       , emit: kmer_histo

    when:
    task.ext.when == null || task.ext.when

    script:
    """
    yak inspect $yakfile > ${yakfile}.hist
    """
}
