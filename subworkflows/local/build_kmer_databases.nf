include { FASTK_FASTK     } from "$projectDir/modules/nf-core/modules/fastk/fastk/main"
include { FASTK_MERGE     } from "$projectDir/modules/nf-core/modules/fastk/merge/main"
include { MERYL_COUNT     } from "$projectDir/modules/nf-core/modules/meryl/count/main"
include { MERYL_UNIONSUM  } from "$projectDir/modules/nf-core/modules/meryl/unionsum/main"
include { MERYL_HISTOGRAM } from "$projectDir/modules/nf-core/modules/meryl/histogram/main"

workflow BUILD_KMER_DATABASES {

    take:
    fastx_data

    main:
    fastx_data.branch {
        fastk_ch: !params.enable_conda && params.kmer_counter == 'fastk'
        meryl_ch: true
    }.set { kmer_counter }

    // FastK K-mer counter
    FASTK_FASTK( kmer_counter.fastk_ch )
    fkdb_ch = FASTK_FASTK.out.hist.groupTuple()
        .join( FASTK_FASTK.out.ktab.groupTuple(), remainder: true )
        .join( FASTK_FASTK.out.prof.groupTuple(), remainder: true )
        .map { meta, hist, ktab, prof -> [meta, hist, ktab ? ktab.flatten() : [] , prof ? prof.flatten() : [] ] }
        .branch { meta, hist, ktab, prof ->
            single_hist: hist.size() == 1
            multi_hist : hist.size() > 1
        }
    FASTK_MERGE ( fkdb_ch.multi_hist )
    fk_single = fkdb_ch.single_hist.multiMap { meta, hist, ktab, prof ->
        hist: [ meta, hist ]
        ktab: [ meta, ktab ]
        prof: [ meta, prof ]
    }
    versions_ch = FASTK_FASTK.out.versions.first().mix( FASTK_MERGE.out.versions.first() )

    // Meryl K-mer counter
    MERYL_COUNT ( kmer_counter.meryl_ch )
    MERYL_UNIONSUM ( MERYL_COUNT.out.meryl_db )
    MERYL_HISTOGRAM ( MERYL_UNIONSUM.out.meryl_db )
    versions_ch = versions_ch.mix(
        MERYL_COUNT.out.versions.first(),
        MERYL_UNIONSUM.out.versions.first(),
        MERYL_HISTOGRAM.out.versions.first()
    )

    emit:
    fastk_histogram = fk_single.hist.mix( FASTK_MERGE.out.hist )
    fastk_ktab      = fk_single.ktab.mix( FASTK_MERGE.out.ktab )
    fastk_prof      = fk_single.prof.mix( FASTK_MERGE.out.prof )
    meryl_histogram = MERYL_HISTOGRAM.out.hist
    meryl_uniondb   = MERYL_UNIONSUM.out.meryl_db
    versions        = versions_ch
}
