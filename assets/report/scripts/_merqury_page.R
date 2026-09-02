# This generates the tab-page for each sample
# Per sample there are 3 value boxes
# Below the value boxes there is a tabset of plots, each tab contains one of the plot-types produced above.
# Those are: Completeness, k-mer specatr, QV and CN

for (i in 1:length(unique(merqury_stats$group))) {
  cur_group <- unique(merqury_stats$group)[i]
  cat(
    paste0('### ', cur_group, '\n\n'),
    paste0('merqury creates assembly statistics, through comparisons of the k-mer spectrum of short-reads to the k-mer spectrum of an assembly.\n\n'),
    paste0('::: {.panel-tabset} \n\n'),
    paste0('#### Completeness \n'),
    paste0('\n'),
    knitr::knit_child(glue::glue('merqury_files/stat_plots/_{ cur_group }_completeness_plt.Rmd'),
                      envir = globalenv(),
                      quiet = TRUE),
    paste0('\n'),
    paste0('#### QV \n'),
    paste0('\n'),
    paste0('QV is defined as:\n', expression(10*-log10(error_rate))),
    paste0('\n'),
    knitr::knit_child(glue::glue('merqury_files/qv_plots/_{ cur_group }_qv_plt.Rmd'),
                      envir = globalenv(),
                      quiet = TRUE),
    paste0('\n'),
    paste0('#### Spectra \n'),
    paste0('\n'),
    knitr::knit_child(glue::glue('merqury_files/asm_plots/_{ cur_group }_asm_plt.Rmd'),
                      envir = globalenv(),
                      quiet = TRUE),
    paste0('\n'),
    paste0('#### Copy Number \n'),
    paste0('\n'),
    knitr::knit_child(glue::glue('merqury_files/cn_plots/_{ cur_group }_cn_plt.Rmd'),
                      envir = globalenv(),
                      quiet = TRUE),
    paste0('\n\n\n'),
    paste0(':::'),
    paste0('\n\n\n'),
    sep = "")
}
