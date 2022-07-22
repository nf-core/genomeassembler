include { FASTK_HISTEX } from "$projectDir/modules/nf-core/modules/fastk/histex/main"
include { GENESCOPEFK  } from "$projectDir/modules/nf-core/modules/genescopefk/main"
include { GENOMESCOPE2 } from "$projectDir/modules/nf-core/modules/genomescope2/main"

include { MERQURYFK_PLOIDYPLOT } from "$projectDir/modules/nf-core/modules/merquryfk/ploidyplot/main"
include { MERQURYFK_KATGC      } from "$projectDir/modules/nf-core/modules/merquryfk/katgc/main"

workflow GENOME_PROPERTIES {

    take:
    fastk_hist_ktab   // [ meta, fastk_hist, fastk_ktab ]
    meryl_histogram   // [ meta, meryl_db ]

    /* Genome properties workflow:
        - Estimate genome depth of coverage from reads
        - Generate k-mer histogram
        - Smudgeplot
    */
    main:
    // Generate GenomeScope Profile
    FASTK_HISTEX ( fastk_hist_ktab.map { meta, hist, ktab -> [ meta, hist ] } )
    GENESCOPEFK ( FASTK_HISTEX.out.hist )
    GENOMESCOPE2 ( meryl_histogram )

    // Generate Smudgeplot
    MERQURYFK_PLOIDYPLOT ( fastk_hist_ktab )

    // Generage GC plot
    MERQURYFK_KATGC ( fastk_hist_ktab )

    versions_ch = FASTK_HISTEX.out.versions.first().mix(
            GENESCOPEFK.out.versions.first(),
            GENOMESCOPE2.out.versions.first(),
            MERQURYFK_PLOIDYPLOT.out.versions.first(),
            MERQURYFK_KATGC.out.versions.first()
        )

    emit:
    versions = versions_ch
}
