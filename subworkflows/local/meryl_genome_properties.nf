include { GENOMESCOPE2 } from "$projectDir/modules/nf-core/genomescope2/main"

workflow MERYL_GENOME_PROPERTIES {

    take:
    meryl_histogram   // [ meta, meryl_db ]

    /* Genome properties workflow:
        - Estimate genome depth of coverage from reads
        - Generate k-mer histogram
        - Smudgeplot
    */
    main:
    // Generate GenomeScope Profile
    GENOMESCOPE2 ( meryl_histogram )
    versions_ch = GENOMESCOPE2.out.versions.first()

    emit:
    versions = versions_ch
}
