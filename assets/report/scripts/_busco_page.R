# This generates a tab-page for each sample

for (i in 1:length(unique(busco_reports$group))) {
  cur_group <-  unique(busco_reports$group)[i]
  cat(
    paste0('### ', cur_group, '\n\n'),
    paste0('::: {.panel-tabset} \n\n'),
    paste0('#### Tabular \n\n'),
    busco_reports |>
      filter(group == cur_group) |>
      dplyr::select(sample, stage, Var, value) |>
      mutate(Var = str_replace_all(Var, "_", " ") |> str_replace_all("percent", "(%)")) |>
      pivot_wider(names_from = "Var", values_from = "value", id_cols = c(sample,stage)) |>
      dplyr::arrange(factor(stage, levels = c("Assembly","medaka", "pilon", "dorado","hic","links","longstitch","ragtag")), sample) |>
      gt::gt() |>
      gt::fmt_auto() |>
      gt::opt_stylize(color = "gray") |>
      gt::opt_table_font(
        font = list(
          gt::google_font(name = "Maven Pro"),
          "rounded-sans"
        )) |>
      gt::as_raw_html(),
    paste0('\n\n'),
    paste('#### Plot'),
    paste0('\n\n'),
    knitr::knit_child(glue::glue('busco_files/orthologs/_{ unique(busco_reports$group)[i] }_orthologs.Rmd'),
                      envir = globalenv(),
                      quiet = TRUE),
    paste0('\n\n\n'),
    paste0(':::\n\n'),
    sep = "")
}
