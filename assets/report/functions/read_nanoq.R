library(magrittr)
library(tidyjson)
library(dplyr)
library(readr)

# Read a nanoq json report
read_nanoq <- function(file) {
  bind_rows(
    read_json(file) %>%
      tidyjson::spread_all() %>%
      as_tibble() %>%
      select(-document.id) %>%
      pivot_longer(everything(), values_to = "val", names_to = "stat"),
    read_json(file) %>%
      enter_object(top_lengths) %>%
      gather_array() %>%
      unnest(cols = c(..JSON)) %>%
      mutate(stat = "longest") %>%
      dplyr::select(4, val = 3)
  ) %>%
    mutate(sample = str_extract(file, '(?<=nanoq/).+?(?=_report)'),
           stage = "Reads") %>%
    mutate(
      stat = stat %>%
        str_replace_all("_", " ") %>%
        str_to_title() %>%
        str_replace("Reads", "N Reads")
    )
}