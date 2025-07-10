plot_merqury_stats <- function(data, groupname) {
  data %>%
    filter(group == paste(groupname)) %>%
    ggplot(aes(x = stage, y = assembly*100/total, color = sample, fill = sample)) +
    geom_line(aes(group = sample)) +
    geom_point(size = 7, color = "black", pch=21) +
    labs(
      y = "k-mer completeness [%]",
      x = "Stage",
      color = "k-mers copy number",
      fill = "k-mers copy number",
      title = glue::glue("k-mer completeness {groupname} assemblies")
    )
}

plot_merqury_multiplicity <- function(data, groupname) {
  y_max <- data %>%
    filter(group == paste(groupname), Assembly != "read-only") %$%
    max(Count)
  x_max <- data %>%
    filter(group == paste(groupname), Assembly != "read-only") %$%
    quantile(Count, .95)
  data %>%
    filter(group == paste(groupname)) %>%
    mutate(Assembly = case_when(Assembly == "read-only" ~ "Reads", TRUE ~ "Assembly")) %>%
    ggplot(aes(x = kmer_multiplicity, y = Count)) +
    geom_line(aes(color = Assembly)) +
    #geom_area(aes(fill = Assembly), alpha = 0.15,stat = "identity") +
    facet_grid(sample ~ stage) +
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
      title = glue::glue("k-mer multiplicity across {groupname} assemblies")
    ) +
    theme(legend.position = "bottom") +
    color_scale_plots +
    fill_scale_plots
}

plot_merqury_copynumber <- function(data, groupname) {
  y_max <- data %>%
    filter(group == paste(groupname), Copies != "read-only") %$%
    max(Count)
  x_max <- data %>%
    filter(group == paste(groupname), Copies != "read-only") %$%
    quantile(Count, .965)
  data %>%
    filter(group == paste(groupname)) %>%
    ggplot(aes(x = kmer_multiplicity, y = Count)) +
    geom_line(aes(color = Copies)) +
    #geom_area(aes(fill = Copies), alpha = 0.15, stat = "identity") +
    facet_grid(sample ~ stage) +
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
      title = glue::glue("k-mer copy number across {groupname} assemblies")
    ) +
    theme(legend.position = "bottom") +
    color_scale_plots +
    fill_scale_plots
}

plot_merqury_qv <- function(data, groupname) {
  data %>%
    filter(group == paste(groupname)) %>%
    ggplot(aes(x = stage, y = QV, color = sample, fill = sample)) +
    geom_line(aes(group = sample)) +
    geom_point(
      pch = 21,
      color = "black",
      size = 5
    ) +
    labs(y = "QV", x = "Stage", title = "QV across assembly stages")
}
