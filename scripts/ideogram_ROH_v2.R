library(ggplot2)
library(dplyr)

specimens <- c("femurXIII", "femur_fragment", "molar_L35", "scapula")
labels_sp <- c("FemurXIII", "Femur fragment", "Molar L35", "Scapula")
autosomes <- paste0("chr", 1:22)

all_data <- data.frame()
for (i in seq_along(specimens)) {
  sp <- specimens[i]
  df <- read.table(
    gzfile(paste0("~/PopSize/results/roh/", sp, ".mid.hmmp.gz")),
    header = TRUE, sep = "\t", comment.char = "#",
    col.names = c("chrom", "begin", "end", "p_roh", "p_nonroh"),
    na.strings = "NA"
  )
  df <- df[df$chrom %in% autosomes, ]
  df$p_roh[is.na(df$p_roh)] <- 0  # NA → 0 (sin cobertura = blanco)
  df$specimen <- labels_sp[i]
  df$chr_num <- as.integer(sub("chr", "", df$chrom))
  df$mid <- (df$begin + df$end) / 2e6
  all_data <- rbind(all_data, df)
}

all_data$specimen <- factor(all_data$specimen, levels = rev(labels_sp))
all_data$chrom <- factor(all_data$chrom,
                         levels = autosomes,
                         labels = paste0("Chr ", 1:22))

p <- ggplot(all_data, aes(x = mid, y = specimen, fill = p_roh)) +
  geom_tile(width = 3, height = 0.85) +
  facet_wrap(~ chrom, nrow = 4, scales = "free_x") +
  scale_fill_gradientn(
    colors = c("white", "#E6F1FB", "#85B7EB", "#185FA5", "#042C53"),
    values = c(0, 0.05, 0.20, 0.50, 1),
    limits = c(0, 1),
    name = "p(ROH)",
    breaks = c(0, 0.25, 0.5, 0.75, 1),
    labels = c("0", "0.25", "0.50", "0.75", "1.0"),
    na.value = "white"
  ) +
  labs(
    title = "ROH probability across autosomes - Sima de los Huesos (~430 ka)",
    subtitle = "ROHan HMM posterior p(ROH) per 3 Mb window (mid estimate)  .  hg38  .  transversions only",
    x = "Position (Mb)",
    y = NULL
  ) +
  theme_minimal(base_size = 9) +
  theme(
    plot.background  = element_rect(fill = "white", color = NA),
    panel.background = element_rect(fill = "white", color = NA),
    strip.background = element_rect(fill = "grey92", color = NA),
    strip.text  = element_text(size = 8, face = "bold", color = "black"),
    axis.text.x = element_text(size = 6, color = "grey40"),
    axis.text.y = element_text(size = 8, color = "black"),
    legend.position = "right",
    legend.title = element_text(size = 9),
    panel.grid = element_blank(),
    plot.title    = element_text(size = 11, face = "bold", color = "black"),
    plot.subtitle = element_text(size =  8, color = "grey40"),
    panel.spacing = unit(0.4, "lines")
  )

ggsave("~/PopSize/results/ideogram_ROH_SH_v2.pdf",
       p, width = 16, height = 10, device = "pdf", bg = "white")
ggsave("~/PopSize/results/ideogram_ROH_SH_v2.png",
       p, width = 16, height = 10, dpi = 300, bg = "white")

cat("✓ Ideograma v2 guardado\n")

# Estadísticas por espécimen
cat("\n=== p(ROH) media por espécimen ===\n")
all_data %>%
  group_by(specimen) %>%
  summarise(
    mean_pROH = round(mean(p_roh, na.rm=TRUE), 4),
    max_pROH  = round(max(p_roh,  na.rm=TRUE), 4),
    n_windows = n()
  ) %>% print()
