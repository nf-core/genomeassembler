sample_overview <- function(groups, quast = NULL, busco = NULL, merqury = NULL) {
  identities <- groups |>
    distinct(sample, sample_id, haplotype) |>
    mutate(assembly = if_else(is.na(haplotype) | haplotype == "null" | haplotype == "",
                              "Unphased", haplotype))
  metrics <- list()
  if (!is.null(quast) && nrow(quast) > 0) {
    metrics$quast <- quast |>
      filter(stat %in% c("Total length", "# contigs", "N50", "N90")) |>
      transmute(sample, stage = as.character(stage), tool = "QUAST", metric = stat, value)
  }
  if (!is.null(busco) && nrow(busco) > 0) {
    metrics$busco <- busco |>
      filter(Var %in% c("Complete", "Single", "Duplicated", "Fragmented", "Missing")) |>
      transmute(sample, stage = as.character(stage), tool = "BUSCO",
                metric = paste0(Var, " (%)"), value)
  }
  if (!is.null(merqury) && nrow(merqury) > 0) {
    metrics$merqury <- merqury |>
      transmute(sample, stage = as.character(stage), tool = "Merqury", metric = "QV", value = QV)
  }
  if (length(metrics) == 0) return(tibble())
  # Keep non-additive QC statistics separate for each haplotype.
  bind_rows(metrics) |>
    select(sample, stage, tool, metric, value) |>
    distinct() |>
    inner_join(identities, by = "sample", relationship = "many-to-one") |>
    select(sample_id, stage, tool, metric, assembly, value) |>
    pivot_wider(names_from = assembly, values_from = value) |>
    arrange(sample_id, stage, tool, metric)
}
