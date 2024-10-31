## WIP
read_genomescope <- function(path) {
  rbind(
    read_table(path, skip = 3, n_max = 1) %>% dplyr::select(-X4),
    read_table(
      path,
      skip = 5,
      n_max = 3,
      col_names = c(
        "property",
        "property2",
        "property3",
        "min",
        "bp",
        "max",
        "bp2"
      )
    ) %>%
      dplyr::select(-starts_with("bp")) %>%
      mutate(property = glue::glue("{property} {property2} {property3}")) %>%
      dplyr::select(-property2, -property3),
    read_table(
      path,
      skip = 8,
      n_max = 1,
      c("property", "property2", "min", "max")
    ) %>%
      mutate(property = glue::glue("{property} {property2}")) %>%
      dplyr::select(-property2),
    read_table(
      path,
      skip = 9,
      n_max = 1,
      c("property", "property2", "property3", "min", "max")
    ) %>%
      mutate(property = glue::glue("{property} {property2} {property3}")) %>%
      dplyr::select(-property2, -property3)
  ) %>%
    mutate(
      min = str_extract(min, "[0-9\\.]+") %>% as.numeric(),
      max = str_extract(max, "[0-9\\.]+") %>% as.numeric()
    ) %>%
    mutate(sample = str_extract(path %>% basename(), ".+?(?=_genomescope)"))
}
