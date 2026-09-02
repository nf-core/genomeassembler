# Parse BUSCO reports

busco_reports <- list.files(paste0(data_base, "busco"),
                            full.names = T,
                            pattern = "batch_summary") |>
  map_dfr(\(x) read_busco_batch(x)) |>
  left_join(groups, by = join_by(sample))

dir.create("busco_files")
dir.create("busco_files/orthologs")

# Create BUSCO plot
for (i in 1:length(unique(busco_reports$group))) {
    cur_group <- unique(busco_reports$group)[i]
    group_size <- busco_reports |> filter(group == cur_group) |> _$sample |> unique() |> length()
    plt_height <- case_when(group_size < 5 ~ 7, TRUE ~ group_size+3)
    paste0('```{r echo = F, fig.height = ',plt_height,'}
            p <- busco_reports |>
                filter(group == "', unique(busco_reports$group)[i], '") |>
                filter(Var %in% c("Complete","Single","Duplicated","Fragmented")) |>
                ggplot(aes(y = value, x = Var)) +
                geom_point(
                    aes(fill = stage),
                    size = 6,
                    pch = 21,
                    alpha = 0.8,
                    position = position_dodge(width = 0.4)
                ) +
                facet_wrap( ~ sample, nrow = 3) +
                fill_scale_plots +
                labs(   y = "% of Single Copy Orthologs",
                        title = "BUSCO: Conserved Orthologs") +
                coord_cartesian(clip = "on") +
                theme(
                    panel.border = element_rect(fill = NA),
                    legend.position = "bottom",
                    axis.title.y = element_text(angle = 90),
                    axis.title.x = element_blank()
                )
                p
                \n```') |>
    write_lines(glue::glue("busco_files/orthologs/_{ unique(busco_reports$group)[i] }_orthologs.Rmd"))
}
