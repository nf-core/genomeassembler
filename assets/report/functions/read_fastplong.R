library(magrittr)
library(tidyjson)
library(dplyr)
library(readr)

# Read a nanoq json report
read_fastplong <- function(file) {
  group_name <- file %>% str_extract('(?<=fastplong/).+?(?=_(ont|hifi)\\.fastplong\\.json)')
  read_type <- file %>%
    str_extract('(?<=fastplong/).*') %>%
    str_extract('_(ont|hifi)\\.') %>%
    str_remove_all("_|\\.") |>
    str_replace("ont", "ONT") |>
    str_replace("hifi", "PB HiFi")
  read_json(file) %>%
      enter_object("summary") %>%
      tidyjson::spread_all() %>%
      as_tibble() %>%
      select(-document.id,-fastplong_version) %>%
      pivot_longer(everything(),
                   names_to = c("stage", "stat"),
                   names_pattern = "(.*)\\.(.*)") %>%
    mutate(group = group_name) %>%
    mutate(
      stat = stat %>%
        str_replace_all("_", " ") %>%
        str_to_title(),
      stage = stage %>%
        str_replace_all("_", " ") %>%
        str_to_title(),
      read_type = read_type
    )
}
