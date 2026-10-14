library(tidyverse)
source('assets/report/functions/sample_overview.R')
groups <- tibble(sample = c('sampleA_hap1', 'sampleA_hap2', 'sampleB', 'sampleA_hap1'),
                 sample_id = c('sampleA', 'sampleA', 'sampleB', 'sampleA'),
                 haplotype = c('hap1', 'hap2', NA, 'hap1'))
quast <- tibble(sample = c('sampleA_hap1', 'sampleA_hap2', 'sampleB', 'sampleA_hap1'),
                stage = c('Assembly', 'Assembly', 'Assembly', 'pilon'),
                stat = 'N50', value = c(100, 200, 300, 400))
busco <- tibble(sample = c('sampleA_hap1', 'sampleA_hap2'), stage = 'Assembly',
                Var = 'Complete', value = c(90, 95))
merqury <- tibble(sample = c('sampleA_hap1', 'sampleA_hap2'), stage = 'Assembly', QV = c(40, 50))
overview <- sample_overview(groups, quast, busco, merqury)
stopifnot(nrow(overview) == 5, !any(vapply(overview, is.list, logical(1))))
initial <- overview |> filter(sample_id == 'sampleA', tool == 'QUAST', stage == 'Assembly')
stopifnot(initial$hap1 == 100, initial$hap2 == 200)
polished <- overview |> filter(sample_id == 'sampleA', stage == 'pilon')
stopifnot(polished$hap1 == 400, is.na(polished$hap2))
stopifnot((overview |> filter(sample_id == 'sampleB'))$Unphased == 300)
stopifnot((overview |> filter(tool == 'BUSCO'))$hap1 == 90,
          (overview |> filter(tool == 'Merqury'))$hap2 == 50)
stopifnot(nrow(sample_overview(groups)) == 0)
html <- overview |> gt::gt(groupname_col = 'sample_id') |>
  gt::sub_missing(missing_text = 'Not available') |> gt::as_raw_html()
stopifnot(grepl('sampleA', html), grepl('hap1', html), grepl('hap2', html),
          grepl('Not available', html))
cat('Sample overview regression checks passed.\n')
