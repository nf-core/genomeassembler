# This file parses QUAST outputs and creates the templates for plotting.

# Parse the quast reports from data/quast
quast_stats <- list.files(paste0(data_base, "quast"),
                          pattern = "\\.tsv$",
                          full.names = T) |>
  map_dfr(\(x) {
    read_quast_report(x) |>
      mutate(
        # Get sample name by matching filename to samples in groups, reverse sort by length to hopefully catch
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
  left_join(groups, by = join_by(sample)) |>
  mutate(stage = stage |> fct_relevel("Assembly", "medaka", "dorado", "pilon", "longstitch", "LINKS", "HiC", "RagTag") ) |>
  dplyr::arrange(sample, stage)

# This creates code that will generate the length plot based on the contents of the quast report.
dir.create("quast_files")
dir.create("quast_files/length")
for (i in 1:length(unique(quast_stats$group))) {
  cur_group <- unique(quast_stats$group)[i]
  group_size <- quast_stats |> filter(group == cur_group) |> _$sample |> unique() |> length()
  plt_height <- case_when(group_size < 5 ~ 7, TRUE ~ group_size+3)
  paste0('```{r echo = F, fig.height = ',plt_height,'}
      quast_stats |>
        filter(group == "', unique(quast_stats$group)[i], '") |>
        filter(str_detect(stat, "[L].*[59]0")) |>
        mutate(stat = fct_relevel(stat, "L50","L90","LG50","LG90")) |>
        ggplot(aes(x = stat, y = value)) +
          geom_point(
            aes(fill = stage),
            size = 5,
            pch = 21,
            height = 0,
            width = 0.2,
            alpha = 0.8,
            position = position_dodge(width = 0.4)
          ) +
          facet_wrap(~ sample, scales = "free_y") +
          fill_scale_plots +
          theme_bw(base_size = 14) +
          theme(
            axis.title.x = element_blank(),
            strip.background = element_blank(),
            legend.position = "bottom",
            axis.text.x = element_text(angle = 60, hjust = 1)
          ) +
          scale_y_continuous(
            labels = function(x)
              format(
                x,
                scientific = -1,
                trim = T,
                digits = 3,
                drop0trailing = T
              )
          ) +
          labs(y = "Aggregated length of contigs in bin")\n```') |>
    write_lines(glue::glue("quast_files/length/_{ unique(quast_stats$group)[i] }_quast.Rmd"))
}

dir.create("quast_files/contigs")
for (i in 1:length(unique(quast_stats$group))) {
  cur_group <- unique(quast_stats$group)[i]
  group_size <- quast_stats |> filter(group == cur_group) |> _$sample |> unique() |> length()
  plt_height <- case_when(group_size < 5 ~ 7, TRUE ~ group_size+3)
  paste0('```{r echo = F, fig.height = ',plt_height,'}
    quast_stats |>
    filter(group == "', unique(quast_stats$group)[i], '") |>
    filter(str_detect(stat, "# contigs \\\\(")) |>
    filter(!str_detect(stat, ">= 0")) |>
    mutate(stat = stat |> str_remove_all("# contigs ") |> str_remove_all("[()]") |> fct_inorder()) |>
    ggplot(aes(x = stat, y = value)) +
    geom_point(
      aes(fill = stage),
      size = 5,
      pch = 21,
      alpha = 0.8,
      position = position_dodge(width = 0.4)
    ) +
    facet_wrap(~ sample, scales = "free_y") +
    fill_scale_plots +
    theme_bw(base_size = 14) +
    theme(
      axis.title.x = element_blank(),
      axis.title.y = element_blank(),
      strip.background = element_blank(),
      legend.position = "bottom",
      axis.text.x = element_text(angle = 60, hjust = 1)
    )
    \n```') |>
    write_lines(glue::glue("quast_files/contigs/_{ unique(quast_stats$group)[i] }_quast.Rmd"))
}

# This creates code that will generate the contig plots based on the contents of the quast report.
dir.create("quast_files/NL_plots")
for (i in 1:length(unique(quast_stats$group))) {
  cur_group <- unique(quast_stats$group)[i]
  group_size <- quast_stats |> filter(group == cur_group) |> _$sample |> unique() |> length()
  plt_height <- case_when(group_size < 5 ~ 7, TRUE ~ group_size+3)
  paste0('```{r echo = F, fig.height = ',plt_height,'}
    quast_stats |>
    filter(group == "', unique(quast_stats$group)[i], '") |>
    filter(str_detect(stat, "[N].*[59]0")) |>
    ggplot(aes(y = stat, x = value)) +
    geom_point(
      aes(fill = stage),
      size = 5,
      pch = 21,
      alpha = 0.8,
      position = position_dodge(width = 0.4)
    ) +
    facet_wrap(~sample, scales = "free") +
    theme_bw(base_size = 14) +
    theme(
      axis.title = element_blank(),
      strip.background = element_blank(),
      legend.position = "bottom",
      axis.text.x = element_text(angle = 60, hjust = 1)
    ) +
    fill_scale_plots
    \n```') |>
    write_lines(glue::glue("quast_files/NL_plots/_{ unique(quast_stats$group)[i] }_N_quast.Rmd"))
  paste0('```{r echo = F, fig.height = ',plt_height,'}
    quast_stats |>
    filter(group == "', unique(quast_stats$group)[i], '") |>
    filter(str_detect(stat, "[L].*[59]0")) |>
    ggplot(aes(y = stat, x = value)) +
    geom_point(
      aes(fill = stage),
      size = 5,
      pch = 21,
      alpha = 0.8,
      position = position_dodge(width = 0.4)
    ) +
    facet_wrap(~sample, scales = "free") +
    theme_bw(base_size = 14) +
    theme(
      axis.title = element_blank(),
      strip.background = element_blank(),
      legend.position = "bottom",
      axis.text.x = element_text(angle = 60, hjust = 1)
    ) +
    fill_scale_plots
    \n```') |>
    write_lines(glue::glue("quast_files/NL_plots/_{ unique(quast_stats$group)[i] }_L_quast.Rmd"))
}
