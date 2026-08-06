# This generates a tab-page for each sample

for (i in 1:length(unique(quast_stats$group))) {
  cat(paste0('### ', unique(quast_stats$group)[i], '\n\n'),
      paste0('::: {.panel-tabset} \n\n'),
      paste0('#### Tabular \n\n'),
      paste0('::::: {.panel-tabset} \n\n'),
      paste0('##### Overview \n\n'),
      quast_stats |>
        filter(group == unique(quast_stats$group)[i]) |>
        dplyr::select(sample, stage, stat, value) |>
        pivot_wider(names_from = "stat", values_from = "value",id_cols = c(sample, stage)) |>
        dplyr::arrange(stage, sample) |>
        dplyr::select(
          sample,
          stage,
          `# contigs`,
          `Largest contig`,
          starts_with("# contigs ("),
          `Total length`,
          `Reference length` ,
          starts_with("Total length ("),
          `GC (%)`
        ) |>
        gt::gt() |>
        gt::cols_nanoplot(columns = starts_with("# contigs ("),
                          new_col_name = "Contigs_by_size",
                          new_col_label = gt::md("*# Contigs by size*")) |>
        gt::cols_nanoplot(columns = starts_with("Total length ("),
                          new_col_name = "Total_length",
                          new_col_label = gt::md("*Total length*")) |>
        gt::tab_footnote(
          footnote = "Breaks are: contigs >= 0, 1kb, 5kb, 10kb, 25kb, 50kb",
          locations = gt::cells_column_labels(columns = c(Contigs_by_size, Total_length))) |>
        gt::cols_align(align = "center", columns = c(Contigs_by_size, Total_length)) |>
        gt::cols_move(Contigs_by_size, "Largest contig") |>
        gt::cols_move(Total_length, "Total length") |>
        gt::fmt_auto() |>
        gt::fmt_scientific(columns = c("Largest contig", "Total length", "Reference length")) |>
        gt::opt_stylize(color = "gray") |>
        gt::opt_table_font(
          font = list(
            gt::google_font(name = "Maven Pro"),
            "rounded-sans"
          )) |>
        gt::as_raw_html()
      ,
      paste0('\n\n'),
      paste0('##### N/L 50/90  \n\n'),
      paste0('N50: length of a contig, such that all the contigs of at least the same length together cover at least 50% of the assembly.<br>N90: same as N50 but the contigs cover 90% of the assembly.<br>NG 50/90: Similar to N50/90, but measures coverage of the reference.<br>L measures the number of contigs required to cover 50 (or 90) % of the assembly length.<br>LG measures the number of contigs to cover the given percentage of the reference.\n\n'),
      quast_stats |>
        filter(group == unique(quast_stats$group)[i]) |>
        filter(str_detect(stat, "[NLG].*[59]0")) |>
        dplyr::select(sample, stage, stat, value) |>
        pivot_wider(names_from = "stat", values_from = "value",id_cols = c(sample, stage)) |>
        dplyr::arrange(stage, sample) |>
        gt::gt() |>
        gt::fmt_auto() |>
        gt::fmt_scientific(columns = starts_with("N")) |>
        gt::opt_stylize(color = "gray") |>
        gt::opt_table_font(
          font = list(
            gt::google_font(name = "Maven Pro"),
            "rounded-sans"
          )) |>
        gt::as_raw_html()
      ,
      paste0('\n\n'),
      paste0('##### Comparison to ref  \n\n'),
      quast_stats |>
        filter(group == unique(quast_stats$group)[i]) |>
        filter(
          stat %in% c(
            "Reference mapped (%)",
            "Reference properly paired (%)",
            "Reference avg. coverage depth",
            "Reference coverage >= 1x (%)",
            "# misassemblies",
            "# misassembled contigs",
            "Misassembled contigs length",
            "# local misassemblies"
          )
        ) |>
        dplyr::select(sample, stage, stat, value) |>
        pivot_wider(
          names_from = "stat",
          values_from = "value",
          id_cols = c(sample, stage)
        ) |>
        dplyr::arrange(stage, sample) |>
        gt::gt() |>
        gt::fmt_auto() |>
        gt::opt_stylize(color = "gray") |>
        gt::opt_table_font(
          font = list(
            gt::google_font(name = "Maven Pro"),
            "rounded-sans"
          )) |>
        gt::as_raw_html(),
      paste0(':::::'), # tables tabset
      paste0('\n\n'),
      paste0('#### Visual'),
      paste0('\n\n'),
      paste0('::::: {.panel-tabset} \n\n'),
      paste0('\n\n'),
      paste0('##### Contigs by size\n'),
      knitr::knit_child(glue::glue('quast_files/contigs/_{ unique(quast_stats$group)[i] }_quast.Rmd'),
                        envir = globalenv(),
                        quiet = TRUE),
      paste0('\n\n'),
      paste0('##### N 50 / 90\n'),
      paste0('\n\n'),
      paste0('N50: length of a contig, such that all the contigs of at least the same length together cover at least 50% of the assembly.<br>N90: same as N50 but the contigs cover 90% of the assembly.<br>NG 50/90: Similar to N50/90, but measures coverage of the reference.\n\n'),
      knitr::knit_child(glue::glue('quast_files/NL_plots/_{ unique(quast_stats$group)[i] }_N_quast.Rmd'),
                        envir = globalenv(),
                        quiet = TRUE),
      paste0('\n\n'),
      paste0('##### L 50 / 90'),
      paste0('\n\n'),
      paste0('L measures the number of contigs required to cover 50 (or 90) % of the assembly length, LG measures the number of contigs to cover the given percentage of the reference.\n\n'),
      knitr::knit_child(glue::glue('quast_files/NL_plots/_{ unique(quast_stats$group)[i] }_L_quast.Rmd'),
                        envir = globalenv(),
                        quiet = TRUE),
      paste0('\n\n'),
      paste0('\n\n'),
      paste0(':::::'), # plots tabset
      paste0('\n\n'),
      paste0(':::'), # group tabsets
      paste0('\n\n'),
      sep = "")
}
