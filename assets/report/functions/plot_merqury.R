plot_merqury_stats <- function(data, samplename) {
  data %>%
    filter(sample == paste(samplename)) %>%
    ggplot(aes(x = stage, y = assembly*100/total)) +
    geom_line(aes(group = sample)) +
    geom_point(size = 7, color = "black", fill = "white", pch=21) +
    labs(
      y = "k-mer completeness [%]",
      x = "Stage",
      color = "k-mers copy number",
      fill = "k-mers copy number",
      title = glue::glue("k-mer completeness {samplename} assemblies")
    ) 
}

plot_merqury_multiplicity <- function(data, samplename) {
  y_max <- data %>%
    filter(sample == paste(samplename), Assembly != "read-only") %$%
    max(Count)
  x_max <- data %>%
    filter(sample == paste(samplename), Assembly != "read-only") %$%
    quantile(Count, .95)
  data %>%
    filter(sample == paste(samplename)) %>%
    mutate(Assembly = case_when(Assembly == "read-only" ~ "Reads", TRUE ~ "Assembly")) %>%
    ggplot(aes(x = kmer_multiplicity, y = Count)) +
    geom_line(aes(color = Assembly)) +
    #geom_area(aes(fill = Assembly), alpha = 0.15,stat = "identity") +
    facet_grid( ~ stage) +
    coord_cartesian(
      xlim = c(0, x_max * 1.1),
      ylim = c(0, y_max * 1.05),
      expand = TRUE,
      default = FALSE,
      clip = "on"
    ) +
    labs(
      x = "kmer multiplicity",
      y = "Count",
      color = "k-mers from",
      fill = "k-mers from",
      title = glue::glue("k-mer multiplicity across {samplename} assemblies")
    ) +
    theme(legend.position = "bottom") +
    color_scale_plots +
    fill_scale_plots
}

plot_merqury_copynumber <- function(data, samplename) {
  y_max <- data %>%
    filter(sample == paste(samplename), Copies != "read-only") %$%
    max(Count)
  x_max <- data %>%
    filter(sample == paste(samplename), Copies != "read-only") %$%
    quantile(Count, .965)
  data %>%
    filter(sample == paste(samplename)) %>%
    ggplot(aes(x = kmer_multiplicity, y = Count)) +
    geom_line(aes(color = Copies)) +
    #geom_area(aes(fill = Copies), alpha = 0.15, stat = "identity") +
    facet_grid( ~ stage) +
    coord_cartesian(
      xlim = c(0, x_max * 1.1),
      ylim = c(0, y_max * 1.05),
      expand = TRUE,
      default = FALSE,
      clip = "on"
    ) +
    labs(
      x = "kmer multiplicity",
      y = "Count",
      color = "k-mers copy number",
      fill = "k-mers copy number",
      title = glue::glue("k-mer copy number across {samplename} assemblies")
    ) +
    theme(legend.position = "bottom") +
    color_scale_plots +
    fill_scale_plots
}

plot_merqury_qv <- function(data, samplename) {
  data %>%
    filter(sample == paste(samplename)) %>%
    ggplot(aes(x = stage, y = QV)) +
    geom_line(aes(group = sample)) +
    geom_point(
      pch = 21,
      color = "black",
      fill = "white",
      size = 5
    ) +
    labs(y = "QV", x = "Stage", title = "QV across assembly stages")
}