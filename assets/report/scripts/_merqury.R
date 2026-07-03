# Here the merqury stats are parsed and the assembly stage is extracted
merqury_stats <- list.files(paste0(data_base, "merqury"), full.names = T, pattern = "stats") |>
  lapply(\(x) {
    read_tsv(x, col_names = c("sample_stage","all","assembly","total","percent"), show_col_types = FALSE) |>
      mutate( # Get sample name by matching filename to samples in groups, reverse sort by length to hopefully catch
        # the correct name first in case there is partial overlap between sample names.
        sample = basename(x) |>
          str_extract(groups$sample[rev(order(nchar(groups$sample)))] |> paste(collapse = "|")),
        stage = case_when(
          str_detect(x, "_ragtag") ~ "RagTag",
          str_detect(x, "_medaka") ~ "medaka",
          str_detect(x, "_dorado") ~ "dorado",
          str_detect(x, "_pilon") ~ "pilon",
          str_detect(x, "_longstitch") ~ "longstitch",
          str_detect(x, "_links") ~ "LINKS",
          str_detect(x, "_yahs") ~ "HiC",
          str_detect(x, "assembl[ey]") ~ "Assembly",
          TRUE ~ "Unknown")) }) |>
  bind_rows() |>
  left_join(groups, by = join_by(sample))

# This parses the assembly stats
merqury_asm_hists <- list.files(paste0(data_base, "/merqury"), full.names = T, pattern = "asm.hist")  |>
  lapply(\(x) {
    read_tsv(x, col_names = T, show_col_types = FALSE) |>
      mutate(
        sample = str_extract(x |> basename(),
                             groups$sample[rev(order(nchar(groups$sample)))] |> paste(collapse = "|")),
        stage = case_when(
          str_detect(x, "_ragtag") ~ "RagTag",
          str_detect(x, "_medaka") ~ "medaka",
          str_detect(x, "_dorado") ~ "dorado",
          str_detect(x, "_pilon") ~ "pilon",
          str_detect(x, "_longstitch") ~ "longstitch",
          str_detect(x, "_links") ~ "LINKS",
          str_detect(x, "assembl[ey]") ~ "Assembly",
          TRUE ~ "Unknown"),
        Assembly = as.factor(Assembly),
        stage = as.factor(stage),
        sample = as.factor(sample),
        kmer_multiplicity = as.integer(kmer_multiplicity),
        Count = as.integer(Count))
  }) |>
  bind_rows() |>
  left_join(groups, by = join_by(sample))

# This parses the copy number file
merqury_cn_hists <- list.files(paste0(data_base, "merqury"), full.names = T, pattern = "cn.hist")  |>
  lapply(\(x) {
    read_tsv(x, col_names = T, show_col_types = FALSE) |>
      mutate(
        sample = str_extract(x |> basename(),
                             groups$sample[rev(order(nchar(groups$sample)))] |> paste(collapse = "|")),
        stage = case_when(
          str_detect(x, "_ragtag") ~ "RagTag",
          str_detect(x, "_medaka") ~ "medaka",
          str_detect(x, "_dorado") ~ "dorado",
          str_detect(x, "_pilon") ~ "pilon",
          str_detect(x, "_longstitch") ~ "longstitch",
          str_detect(x, "_links") ~ "LINKS",
          str_detect(x, "assembl[ey]") ~ "Assembly",
          TRUE ~ "Unknown"),
        Copies = as.factor(Copies),
        stage = as.factor(stage),
        sample = as.factor(sample),
        kmer_multiplicity = as.integer(kmer_multiplicity),
        Count = as.integer(Count))
  }) |>
  bind_rows() |>
  left_join(groups, by = join_by(sample))

# This parses the qv file
merqury_qv <- list.files(paste0(data_base, "merqury"), full.names = T, pattern = ".qv") |>
  lapply(\(x) {
    read_tsv(x,
             col_names = c("Assembly", "kmers_assembly_unique", "kmers_assembly_shared", "QV", "error_rate"),
             show_col_types = FALSE) |>
      mutate(
        sample = str_extract(x |> basename(),
                             groups$sample[rev(order(nchar(groups$sample)))] |> paste(collapse = "|")),
        stage = case_when(
          str_detect(x, "_ragtag") ~ "RagTag",
          str_detect(x, "_medaka") ~ "medaka",
          str_detect(x, "_dorado") ~ "dorado",
          str_detect(x, "_pilon") ~ "pilon",
          str_detect(x, "_longstitch") ~ "longstitch",
          str_detect(x, "_links") ~ "LINKS",
          str_detect(x, "assembl[ey]") ~ "Assembly",
          TRUE ~ "Unknown"),
        stage = as.factor(stage),
        sample = as.factor(sample),
        kmers_assembly_shared = as.integer(kmers_assembly_shared),
        kmers_assembly_unique = as.integer(kmers_assembly_unique),
        QV = as.double(QV),
        error_rate = as.double(error_rate))
  }
  ) |>
  bind_rows() |>
  left_join(groups, by = join_by(sample))
dir.create("merqury_files")

# This generates QV-plots from merqury; the plot function is stuffed into plot_merqury
dir.create("merqury_files/qv_plots/")
for (i in 1:length(unique(merqury_qv$group))) {
  cur_group <- unique(merqury_qv$group)[i]
  group_size <- merqury_qv |> filter(group == cur_group) |> _$sample |> unique() |> length()
  plt_height <- case_when(group_size < 5 ~ 7, TRUE ~ group_size+3)
  cur_group <- unique(merqury_qv$group)[i]
  paste0('```{r echo = F, fig.height = ',plt_height,'}
p <- merqury_qv |>
    plot_merqury_qv("', cur_group,'")
print(p)\n```') |>
    write_lines(glue::glue("merqury_files/qv_plots/_{ cur_group }_qv_plt.Rmd"))
}
# This generates stat-plots from merqury; the plot function is stuffed into plot_merqury

dir.create("merqury_files/stat_plots/")
for (i in 1:length(unique(merqury_stats$group))) {
  cur_group <- unique(merqury_stats$group)[i]
  group_size <- merqury_stats |> filter(group == cur_group) |> _$sample |> unique() |> length()
  plt_height <- case_when(group_size < 5 ~ 7, TRUE ~ group_size+3)
  cur_group <- unique(merqury_stats$group)[i]
  paste0('```{r echo = F, fig.height = ',plt_height,'}
p <- merqury_stats |>
    plot_merqury_stats("', cur_group,'")
print(p)\n```') |>
    write_lines(glue::glue("merqury_files/stat_plots/_{ cur_group }_completeness_plt.Rmd"))
}

# This generates assembly plots from merqury; the plot function is stuffed into plot_merqury

dir.create("merqury_files/asm_plots/")
for (i in 1:length(unique(merqury_asm_hists$group))) {
  cur_group <- unique(merqury_asm_hists$group)[i]
  group_size <- merqury_asm_hists |> filter(group == cur_group) |> _$sample |> unique() |> length()
  plt_height <- case_when(group_size < 5 ~ 7, TRUE ~ group_size+3)
  paste0('```{r echo = F, fig.height = ',plt_height,'}
p <- merqury_asm_hists |>
        plot_merqury_multiplicity("', cur_group,'")
print(p)\n```') |>
    write_lines(glue::glue("merqury_files/asm_plots/_{ cur_group }_asm_plt.Rmd"))
}

dir.create("merqury_files/cn_plots/")
for (i in 1:length(unique(merqury_cn_hists$group))) {
  cur_group <- unique(merqury_cn_hists$group)[i]
  group_size <- merqury_cn_hists |> filter(group == cur_group) |> _$sample |> unique() |> length()
  plt_height <- case_when(group_size < 5 ~ 7, TRUE ~ group_size+3)
  paste0('```{r echo = F, fig.height = ',plt_height,'}
p <- merqury_cn_hists |>
        plot_merqury_copynumber("', cur_group,'")
print(p)\n```') |>
    write_lines(glue::glue("merqury_files/cn_plots/_{ cur_group }_cn_plt.Rmd"))
}
