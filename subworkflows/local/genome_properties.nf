include { FASTK_HISTEX } from "$moduleDir/modules/nf-corefastk/histex/main"
include { GENESCOPEFK  } from "$moduleDir/modules/nf-core/genescopefk/main"
include { GENOMESCOPE2 } from "$moduleDir/modules/nf-core/genomescope2/main"

include { MERQURYFK_PLOIDYPLOT } from "$moduleDir/modules/nf-core/merquryfk/ploidyplot/main"
include { MERQURYFK_KATGC      } from "$moduleDir/modules/nf-core/merquryfk/katgc/main"

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
