
read_quast_report <- function(file) {
  assembly = read_tsv(
    file,
    skip = 0L,
    col_names = c("stat", "value"),
    trim_ws = T,
    n_max = 1L,
    show_col_types = FALSE
  ) %$%
    value
  read_tsv(
    file,
    skip = 1L,
    col_names = c("stat", "value"),
    col_types = "cd",
    trim_ws = T,
    n_max = 36L,
    show_col_types = FALSE
  ) %>%
    mutate(assembly = assembly)
}