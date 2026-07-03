# Since genomescope produces plots, I am simply including those here instead of recreating them, the proper QC for kmers comes with merqury.
img_files <- list.files(paste0(data_base,"genomescope"), full.names = T, pattern = "plot.log.png")
dir.create("genomescope_files")
for (file in img_files) {
  file.copy(from = file,
            to   = paste0("genomescope_files/", file |> basename(), sep = ""))

}

img_files <- data.frame(file = list.files("genomescope_files/", full.names = T, pattern = "plot.log.png")) |>
  mutate(group = str_extract(file |> basename(), ".+?(?=_plot.log.png)"))


cat(":::{.panel-tabset}\n\n")
for(grp in unique(img_files$group)) {
  cat(glue::glue('## {grp}\n\n\n'))
  cat(glue::glue('![](<<img_files |> filter(group == grp) %$% file>>){fig-align="centre"}\n\n\n',
                 .open = "<<",
                 .close = ">>"))
}
cat(":::\n")
