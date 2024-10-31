# read busco tsv

read_busco_report <- function(file) {
  assembly <- read_lines(file,
                        skip = 2L,
                        n_max = 1L) %>%
    str_extract('(?<=input_seqs/).+?(?=\\.fa)')
  bind_rows(
    read_tsv(
      file,
      skip = 9L,
      col_names = c("empty", "count", "variable"),
      trim_ws = T,
      n_max = 6L,
      col_select = c(2, 3),
      show_col_types = FALSE
    ) %>%
      magrittr::set_colnames(c("count", "stat")) %>%
      mutate(
        percent = 100 * count / count[stat == "Total BUSCO groups searched"],
        percent = round(percent, 3)
      ),
    read_tsv(
      file,
      skip = 17L,
      col_names = c("empty", "count", "variable"),
      trim_ws = T,
      n_max = 6L,
      col_select = c(2, 3),
      show_col_types = FALSE
    )  %>%
      magrittr::set_colnames(c("count", "stat")) %>%
      dplyr::filter(!stat == "Percent gaps") %>%
      mutate(
        count = case_when(
          str_detect(count, "MB") ~ count %>% str_extract("[0-9]+") %>% as.double() %>% {
            . * 1e6
          },
          str_detect(count, "KB") ~ count %>% str_extract("[0-9]+") %>% as.double() %>% {
            . * 1e3
          },
          TRUE ~ count %>% str_extract("[0-9]+") %>% as.double()
        ),
        percent = NA_real_
      )
  ) %>%
    mutate(assembly = assembly) %>%
    mutate(
      BUSCO = stat %>%
        str_extract("\\(.\\)") %>%
        fct_relevel(c("(C)", "(S)", "(D)", "(F)", "(M)")),
      BUSCO = case_when(
        str_detect(BUSCO, "(C)") ~ "Complete",
        str_detect(BUSCO, "(S)") ~ "Single Copy",
        str_detect(BUSCO, "(D)") ~ "Duplicated",
        str_detect(BUSCO, "(F)") ~ "Fragmented",
        str_detect(BUSCO, "(M)") ~ "Missing",
      )
    )
}