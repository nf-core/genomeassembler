# This loop creates one tab per group
for (i in 1:length(unique(fastplong_reports$group))) {
  cat(paste0('### ', unique(fastplong_reports$group)[i] , '\n\n'),
      paste0('\n\n'),
      paste0('Read filtering and QC results for ', unique(fastplong_reports$group)[i]),
      paste0('\n\n'),
      fastplong_reports |>
        filter(group == unique(fastplong_reports$group)[i]) |>
        dplyr::select(-sample) |>
        unique() |>
        pivot_wider(id_cols = c("stat","group","read_type"), names_from = stage, values_from = value) |>
        mutate(Filtered = `Before Filtering` - `After Filtering` |> round(),
               Filtered = case_when(!str_detect(stat, "Rate|Length|Content") ~ Filtered,
                                    TRUE ~ NA_real_),
               Filtered_Perc = Filtered / `Before Filtering`) |>
        dplyr::select(-group) |>
        dplyr::arrange(
          stat |> fct_relevel(
            "Total Reads",
            "Total Bases",
            "Read Mean Length",
            "Q30 Rate",
            "Q20 Rate",
            "Q30 Bases",
            "Q20 Bases"
          ),
          read_type
        ) |>
        gt::gt() |>
        gt::cols_label(stat = "", read_type = "Read Type", Filtered_Perc = "% filtered") |>
        gt::fmt_auto() |>
        gt::fmt_percent(Filtered_Perc) |>
        gt::tab_footnote(
          footnote = "Due to read splitting it is possible that the number of reads after filtering is larger than before.",
          locations = gt::cells_column_labels(columns = c(Filtered))) |>
        gt::opt_stylize(color = "gray") |>
        gt::as_raw_html(),
      paste0('\n\n'),
      sep = ""
  )
}
